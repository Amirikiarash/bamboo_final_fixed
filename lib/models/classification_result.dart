import 'dart:math' as math;

/// Tunable thresholds for the open-set (out-of-distribution) rejection gate.
///
/// These are literature-informed *starting points*, not values validated on
/// bamboo-weave data. Calibrate them on a small labelled set of real
/// bamboo images plus irrelevant images (lamp, tree, hand, wall) and adjust.
class ClassificationThresholds {
  /// Top-1 softmax probability must be at least this to be accepted.
  final double minTopProb;

  /// Gap between the top-1 and top-2 probability must be at least this.
  final double minMargin;

  /// Normalised entropy (0 = certain, 1 = uniform) must be below this.
  final double maxEntropy;

  const ClassificationThresholds({
    this.minTopProb = 0.55,
    this.minMargin = 0.15,
    this.maxEntropy = 0.80,
  });
}

/// The outcome of interpreting one raw model output vector.
class ClassificationResult {
  /// True when the image is confidently one of the known weave patterns.
  final bool accepted;

  /// Index / label / probability of the best-matching class.
  final int topIndex;
  final String topLabel;
  final double confidence;

  /// Diagnostics used by the rejection gate.
  final double margin;
  final double entropy;

  /// Top matches (label, probability) sorted high-to-low, for display.
  final List<MapEntry<String, double>> topK;

  /// Machine-readable reasons an image was rejected (empty when accepted).
  final List<String> rejectReasons;

  const ClassificationResult({
    required this.accepted,
    required this.topIndex,
    required this.topLabel,
    required this.confidence,
    required this.margin,
    required this.entropy,
    required this.topK,
    required this.rejectReasons,
  });
}

/// Numerically stable softmax.
List<double> softmax(List<double> z) {
  final maxZ = z.reduce(math.max);
  final exps = z.map((v) => math.exp(v - maxZ)).toList();
  final sum = exps.fold<double>(0.0, (a, b) => a + b);
  return exps.map((v) => v / sum).toList();
}

/// Some exported models already apply softmax; others emit raw logits.
/// If the vector is non-negative and sums to ~1 we treat it as probabilities
/// and skip a second (distorting) softmax.
bool looksLikeProbabilities(List<double> z) {
  final allNonNeg = z.every((v) => v >= 0);
  final sum = z.fold<double>(0.0, (a, b) => a + b);
  return allNonNeg && (sum - 1.0).abs() < 0.05;
}

/// Normalised Shannon entropy in [0, 1]. 0 = one class certain, 1 = uniform.
double normalisedEntropy(List<double> p) {
  if (p.length <= 1) return 0.0;
  double h = 0.0;
  for (final pi in p) {
    if (pi > 0) h -= pi * math.log(pi);
  }
  return h / math.log(p.length);
}

/// Turn a raw model output vector into a decision, applying the open-set gate.
///
/// [raw] is the model's output (logits or probabilities). [labels] maps class
/// index to name; missing entries fall back to "Class N".
ClassificationResult interpretOutput(
  List<double> raw,
  List<String> labels, {
  ClassificationThresholds thresholds = const ClassificationThresholds(),
  int topK = 3,
}) {
  final p = looksLikeProbabilities(raw) ? List<double>.from(raw) : softmax(raw);
  final n = p.length;

  String labelFor(int i) =>
      (i >= 0 && i < labels.length && labels[i].trim().isNotEmpty)
          ? labels[i].trim()
          : 'Class $i';

  final order = List<int>.generate(n, (i) => i)
    ..sort((a, b) => p[b].compareTo(p[a]));

  final top1 = order[0];
  final conf = p[top1];
  final second = n > 1 ? p[order[1]] : 0.0;
  final margin = conf - second;
  final entropy = normalisedEntropy(p);

  final reasons = <String>[];
  if (conf < thresholds.minTopProb) reasons.add('low_confidence');
  if (margin < thresholds.minMargin) reasons.add('ambiguous');
  if (entropy > thresholds.maxEntropy) reasons.add('high_entropy');

  final k = math.min(topK, n);
  final top = <MapEntry<String, double>>[
    for (var i = 0; i < k; i++) MapEntry(labelFor(order[i]), p[order[i]]),
  ];

  return ClassificationResult(
    accepted: reasons.isEmpty,
    topIndex: top1,
    topLabel: labelFor(top1),
    confidence: conf,
    margin: margin,
    entropy: entropy,
    topK: top,
    rejectReasons: reasons,
  );
}
