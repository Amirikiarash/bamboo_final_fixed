# 🎋 Bamboo Weave Classifier

A Flutter app that classifies **woven-bamboo patterns** from a photo using an
on-device TensorFlow Lite model. It reports the closest pattern with a
confidence score — and, importantly, **rejects images that are not woven bamboo**
(a lamp, a tree, a hand) instead of confidently mislabelling them.

---

## ✨ Features

- 📷 Capture from **camera** or pick from the **gallery**
- 🧠 On-device inference with TensorFlow Lite (no network needed)
- 📊 Top-3 closest patterns with confidence bars
- 🚫 **Open-set rejection**: unrelated / unclear images are flagged
  "Unrelated or unclear image — please try again", not forced into a class
- 🩺 Graceful model-load error handling with a retry button

---

## 🧩 How the "unrelated image" rejection works

A plain 14-class soft​max classifier will always output *some* class, even for a
photo of a lamp — this was the original failure of the project. The model only
ever saw bamboo during training, so it has no honest way to say "none of these".

This app adds an **inference-time open-set gate** (`lib/models/classification_result.dart`).
After soft​max it accepts a prediction only if **all three** signals agree it is
in-distribution:

| Signal | Meaning | Default gate |
|--------|---------|--------------|
| Top-1 probability | how confident the best class is | must be ≥ `minTopProb` (0.55) |
| Margin (top-1 − top-2) | how clearly one class wins | must be ≥ `minMargin` (0.15) |
| Normalised entropy | how spread-out the distribution is | must be ≤ `maxEntropy` (0.80) |

Using three signals is deliberate (defence in depth): a flat "lamp" output may
slip past one gate but not all three.

> ⚠️ **Honest limitation.** Threshold-based rejection *reduces* false accepts, it
> does not *eliminate* them. A soft​max model never trained on non-bamboo can
> still occasionally be confidently wrong. The durable fix is training-time:
> add a `none / background` class, use OOD-exposure fine-tuning, or a method like
> OpenMax / energy-based detection. The thresholds here are literature-informed
> starting points, **not** values calibrated on real data — see *Calibration*.

---

## ⚙️ Two things you must configure for correct results

### 1. Class labels (`assets/labels.txt`)
The model outputs **14 classes**, but the real pattern names are not stored in
the model. `assets/labels.txt` currently holds placeholders (`Pattern 01 … 14`).
Replace them with the **real pattern names, one per line, in the exact order the
model was trained on**. If the order is wrong, names will be swapped even when
the maths is correct.

### 2. Input normalisation (`lib/services/tflite_service.dart`)
The model expects `FLOAT32` input of shape `[1, 224, 224, 3]`. The pixel
normalisation **must match how the model was trained**, otherwise predictions
are silently wrong. Two schemes are provided via the `Normalization` enum:

```dart
// Default — MobileNet/EfficientNet-lite style, maps [0,255] -> [-1,1]
TFLiteService(normalization: Normalization.minusOneToOne);

// Alternative — Rescaling(1./255) style, maps [0,255] -> [0,1]
TFLiteService(normalization: Normalization.zeroToOne);
```

If confident bamboo photos are misclassified, try switching this first.

---

## 🔬 Calibration (recommended before trusting the output)

1. Collect ~20 real bamboo photos (mix of patterns) and ~20 irrelevant photos
   (lamp, tree, wall, hand).
2. Run them through the app and record accepted/rejected + the reason.
3. Adjust `ClassificationThresholds` to trade off false-accepts vs false-rejects
   for your use case.

---

## 📂 Project structure

```text
lib/
├── main.dart                       # App entry point
├── models/
│   └── classification_result.dart  # Pure decision logic (softmax + open-set gate)
├── services/
│   └── tflite_service.dart         # Model + labels loading, preprocessing, inference
├── screens/
│   └── home_screen.dart            # UI: accepted vs rejected result cards
└── widgets/
    └── image_picker_widget.dart    # Camera + gallery capture
assets/
├── model.tflite                    # 14-class classifier (input 224×224×3 FLOAT32)
└── labels.txt                      # One class name per line (REPLACE placeholders)
```

---

## 📦 Dependencies

```yaml
dependencies:
  image_picker: ^1.1.2   # camera + gallery
  tflite_flutter: ^0.11.0 # on-device inference
  image: ^4.0.17         # decode + resize
```

---

## 🔧 Setup & run

```bash
git clone https://github.com/Amirikiarash/bamboo_final_fixed.git
cd bamboo_final_fixed
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

Run the tests (unit tests for the decision logic + a widget smoke test):

```bash
flutter test
```

---

## 📱 Platforms

Primarily targeted and tested for **Android**. iOS should work (camera/photo
permission strings are included in `Info.plist`) but is untested.

---

## 📍 Author

**Kiarash Amiri** — Machine Learning + Mobile Dev
GitHub: [@Amirikiarash](https://github.com/Amirikiarash)

## 📃 License

MIT License © 2025
