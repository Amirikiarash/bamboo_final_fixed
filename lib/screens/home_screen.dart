import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/classification_result.dart';
import '../services/tflite_service.dart';
import '../widgets/image_picker_widget.dart';

enum _ModelState { loading, ready, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TFLiteService _tflite = TFLiteService();

  _ModelState _modelState = _ModelState.loading;
  String _modelError = '';
  bool _isRunning = false;
  ClassificationResult? _result;
  String _inferenceError = '';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() {
      _modelState = _ModelState.loading;
      _modelError = '';
    });
    try {
      await _tflite.loadModel();
      if (!mounted) return;
      setState(() => _modelState = _ModelState.ready);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modelState = _ModelState.error;
        _modelError = e.toString();
      });
    }
  }

  Future<void> _runModel(File imageFile) async {
    setState(() {
      _isRunning = true;
      _result = null;
      _inferenceError = '';
    });
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw const FormatException('Could not decode this image file.');
      }
      final result = await _tflite.classifyImage(image);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _inferenceError = e.toString());
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  void dispose() {
    _tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bamboo Weave Classifier'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_modelState == _ModelState.error)
              _ModelErrorBanner(message: _modelError, onRetry: _loadModel),
            ImagePickerWidget(
              enabled: _modelState == _ModelState.ready && !_isRunning,
              onImageSelected: _runModel,
            ),
            const SizedBox(height: 20),
            _buildStatusArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusArea() {
    if (_modelState == _ModelState.loading) {
      return const _Centered(child: Text('Loading model…'));
    }
    if (_isRunning) {
      return const _Centered(child: CircularProgressIndicator());
    }
    if (_inferenceError.isNotEmpty) {
      return _InfoCard(
        color: Colors.red,
        icon: Icons.error_outline,
        title: 'Something went wrong',
        body: _inferenceError,
      );
    }
    final result = _result;
    if (result == null) {
      return const _Centered(
        child: Text('Pick or capture a photo of woven bamboo to analyse.'),
      );
    }
    return result.accepted
        ? _AcceptedCard(result: result)
        : _RejectedCard(result: result);
  }
}

class _AcceptedCard extends StatelessWidget {
  final ClassificationResult result;
  const _AcceptedCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.topLabel,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${(result.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Closest matches',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...result.topK.map((e) => _ProbBar(label: e.key, value: e.value)),
          ],
        ),
      ),
    );
  }
}

class _RejectedCard extends StatelessWidget {
  final ClassificationResult result;
  const _RejectedCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      color: Colors.orange,
      icon: Icons.help_outline,
      title: 'Unrelated or unclear image',
      body: 'This does not look like a clear photo of woven bamboo. '
          'Please try again with a well-lit, close-up photo of the weave.\n\n'
          'Best guess would have been "${result.topLabel}" '
          '(${(result.confidence * 100).toStringAsFixed(1)}%), but the model '
          'is not confident enough to report it.',
    );
  }
}

class _ProbBar extends StatelessWidget {
  final String label;
  final double value;
  const _ProbBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              Text('${(value * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.green.withAlpha(31),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _ModelErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ModelErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withAlpha(102)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Failed to load the model',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onRetry, child: const Text('Retry')),
          ),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final Widget child;
  const _Centered({required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(24), child: Center(child: child));
}
