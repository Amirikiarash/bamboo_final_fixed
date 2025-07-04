# 📱 Bamboo Image Classifier

A Flutter application for classifying images of bamboo using a pre-trained TFLite model.

---

## 🚀 Features

- 📷 Pick an image from gallery  
- 🧠 Run image classification using TensorFlow Lite  
- 📊 Display prediction results with confidence  
- ✅ Optimized for Android

---

## 📂 Folder Structure

```plaintext
.
├── assets/
│   └── model.tflite           # Your TensorFlow Lite model
├── lib/
│   ├── main.dart              # Main entry point
│   ├── screens/
│   │   └── home_screen.dart   # Home UI
│   ├── services/
│   │   └── tflite_service.dart# TFLite model loading & inference
│   └── widgets/
│       └── image_picker_widget.dart
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.4
  tflite_flutter: ^0.10.1
  tflite_flutter_helper: ^0.4.0
```

> ⚠️ Make sure your Flutter SDK is compatible with the above versions.

---

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/Amirikiarash/bamboo_final_fixed.git
cd bamboo_final_fixed
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Ensure the model file is in place

The TFLite model should be placed at:

```
assets/model.tflite
```

This is already included in the project. Make sure it's declared in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/model.tflite
```

### 4. Run on Android Device

```bash
flutter run
```

---

## 📤 Build APK

To generate a release APK:

```bash
flutter build apk --release
```

> ⚠️ Note: The app is currently optimized for **Android only**.

---

## 📸 Example Output

When an image is selected, the model returns predictions like:

```text
Predicted Class: Bamboo Culm
Confidence: 94.12%
```

---

## 📍 Author

**Kiarash Amiri**  
🧠 AI + Mobile Dev | 🇮🇷 Based in China  
GitHub: [@Amirikiarash](https://github.com/Amirikiarash)

---

## 📃 License

MIT License © 2025