import '../services/tflite_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../widgets/image_picker_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TFLiteService _tfliteService;
  String _result = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tfliteService = TFLiteService();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _tfliteService.loadModel();
  }

  Future<void> _runModel(File imageFile) async {
    setState(() => _isLoading = true);

    final image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) {
      setState(() {
        _result = '❌ Failed to process image.';
        _isLoading = false;
      });
      return;
    }

    final output = await _tfliteService.runModelOnImage(image);

    setState(() {
      _result = "Output: ${output.map((v) => v.toStringAsFixed(3)).join(', ')}";
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bamboo Classifier'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ImagePickerWidget(
              onImageSelected: _runModel,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(
                _result,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
