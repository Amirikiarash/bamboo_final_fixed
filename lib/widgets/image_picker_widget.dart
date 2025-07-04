import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final void Function(File image) onImageSelected;

  const ImagePickerWidget({super.key, required this.onImageSelected});

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 224,
      maxHeight: 224,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() => _selectedImage = imageFile);
      widget.onImageSelected(imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _selectedImage != null
            ? Image.file(_selectedImage!, height: 200)
            : const Text("No image selected", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo),
          label: const Text("Select from Gallery"),
        ),
      ],
    );
  }
}
