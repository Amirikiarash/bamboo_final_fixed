import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Lets the user provide an image from the camera or the gallery and previews
/// the current selection.
class ImagePickerWidget extends StatefulWidget {
  final void Function(File image) onImageSelected;
  final bool enabled;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.enabled = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024, // bound memory; the model resizes to its own input size
      imageQuality: 90,
    );
    if (picked == null) return;
    final file = File(picked.path);
    setState(() => _selectedImage = file);
    widget.onImageSelected(file);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _selectedImage != null
              ? Image.file(_selectedImage!, height: 220, fit: BoxFit.cover)
              : Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.green.withOpacity(0.08),
                  alignment: Alignment.center,
                  child: const Text(
                    'No image selected',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: widget.enabled ? () => _pick(ImageSource.camera) : null,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Camera'),
            ),
            ElevatedButton.icon(
              onPressed:
                  widget.enabled ? () => _pick(ImageSource.gallery) : null,
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ],
        ),
      ],
    );
  }
}
