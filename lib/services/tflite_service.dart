import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

const int kInputImageSize = 224;
const List<double> kNormMean = [127.5, 127.5, 127.5];
const List<double> kNormStd = [127.5, 127.5, 127.5];

class TFLiteService {
  late Interpreter _interpreter;
  bool _isModelLoaded = false;

  bool get isInitialized => _isModelLoaded;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('model.tflite');
      _isModelLoaded = true;
      if (kDebugMode) {
        print('✅ Interpreter loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load model: $e');
      }
    }
  }

  Future<List<double>> runModelOnImage(img.Image image) async {
    if (!_isModelLoaded) {
      throw Exception("Model is not loaded");
    }

    final inputShape = _interpreter.getInputTensor(0).shape;
    final outputShape = _interpreter.getOutputTensor(0).shape;

    final height = inputShape[1];
    final width = inputShape[2];
    final channels = inputShape[3];

    final resized = img.copyResize(image, width: width, height: height);

    final input = Float32List(1 * height * width * channels);
    int pixelIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        input[pixelIndex++] = (r - kNormMean[0]) / kNormStd[0];
        input[pixelIndex++] = (g - kNormMean[1]) / kNormStd[1];
        input[pixelIndex++] = (b - kNormMean[2]) / kNormStd[2];
      }
    }

    final output =
        List.filled(outputShape[1], 0.0).reshape([1, outputShape[1]]);
    _interpreter.run(input.buffer.asFloat32List(), output);

    return List<double>.from(output[0]);
  }

  void close() {
    if (_isModelLoaded) {
      _interpreter.close();
      _isModelLoaded = false;
      if (kDebugMode) {
        print('Interpreter closed.');
      }
    }
  }
}
