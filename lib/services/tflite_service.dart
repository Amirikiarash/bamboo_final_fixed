import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/classification_result.dart';

/// How pixel values are mapped before being fed to the model. This MUST match
/// the preprocessing used when the model was trained, otherwise predictions are
/// silently wrong. Two most common schemes are provided.
enum Normalization {
  /// pixel/127.5 - 1  ->  range [-1, 1]  (tf.keras MobileNet / EfficientNet-lite)
  minusOneToOne,

  /// pixel/255  ->  range [0, 1]  (Rescaling(1./255) layer, very common in Keras)
  zeroToOne,
}

class ModelLoadException implements Exception {
  final String message;
  ModelLoadException(this.message);
  @override
  String toString() => 'ModelLoadException: $message';
}

class TFLiteService {
  static const String _modelAsset = 'assets/model.tflite';
  static const String _labelsAsset = 'assets/labels.txt';

  final Normalization normalization;
  final ClassificationThresholds thresholds;

  TFLiteService({
    this.normalization = Normalization.minusOneToOne,
    this.thresholds = const ClassificationThresholds(),
  });

  Interpreter? _interpreter;
  List<String> _labels = const [];
  bool _isModelLoaded = false;

  bool get isInitialized => _isModelLoaded;
  List<String> get labels => _labels;

  /// Loads the interpreter and labels. Throws [ModelLoadException] on failure so
  /// the UI can show a real error instead of silently doing nothing.
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelAsset);
      _labels = await _loadLabels();
      _isModelLoaded = true;
      if (kDebugMode) {
        final inShape = _interpreter!.getInputTensor(0).shape;
        final outShape = _interpreter!.getOutputTensor(0).shape;
        debugPrint('✅ Model loaded. input=$inShape output=$outShape '
            'labels=${_labels.length}');
      }
    } catch (e) {
      _isModelLoaded = false;
      throw ModelLoadException(e.toString());
    }
  }

  Future<List<String>> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString(_labelsAsset);
      return raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    } catch (_) {
      return const []; // interpretOutput falls back to "Class N"
    }
  }

  /// Runs inference on [image] and returns a structured, gated result.
  Future<ClassificationResult> classifyImage(img.Image image) async {
    final interpreter = _interpreter;
    if (!_isModelLoaded || interpreter == null) {
      throw ModelLoadException('Model is not loaded');
    }

    final inputShape = interpreter.getInputTensor(0).shape; // [1, H, W, C]
    final outputShape = interpreter.getOutputTensor(0).shape; // [1, N]
    final height = inputShape[1];
    final width = inputShape[2];
    final channels = inputShape[3];
    final numClasses = outputShape[1];

    final resized = img.copyResize(image, width: width, height: height);
    final input = _imageToInput(resized, height, width, channels);

    final output =
        List.filled(numClasses, 0.0).reshape([1, numClasses]);
    interpreter.run(input, output);

    final raw = List<double>.from(output[0].map((v) => (v as num).toDouble()));
    return interpretOutput(raw, _labels, thresholds: thresholds);
  }

  Float32List _imageToInput(img.Image im, int h, int w, int c) {
    final buffer = Float32List(1 * h * w * c);
    var i = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final px = im.getPixel(x, y);
        i = _writeChannel(buffer, i, px.r.toDouble());
        i = _writeChannel(buffer, i, px.g.toDouble());
        i = _writeChannel(buffer, i, px.b.toDouble());
      }
    }
    return buffer;
  }

  int _writeChannel(Float32List buffer, int i, double value) {
    switch (normalization) {
      case Normalization.minusOneToOne:
        buffer[i] = value / 127.5 - 1.0;
        break;
      case Normalization.zeroToOne:
        buffer[i] = value / 255.0;
        break;
    }
    return i + 1;
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
    if (kDebugMode) debugPrint('Interpreter closed.');
  }
}
