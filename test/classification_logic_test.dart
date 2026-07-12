import 'dart:math' as math;

import 'package:bambooapp/models/classification_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final labels = List.generate(14, (i) => 'Pattern ${i + 1}');

  group('softmax', () {
    test('sums to 1 and is monotonic with input', () {
      final p = softmax([8, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
      final sum = p.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-9));
      expect(p[0], greaterThan(p[1]));
    });
  });

  group('looksLikeProbabilities', () {
    test('detects a valid probability vector', () {
      expect(looksLikeProbabilities([0.9, 0.1]), isTrue);
    });
    test('rejects raw logits', () {
      expect(looksLikeProbabilities([8, 1, 1]), isFalse);
      expect(looksLikeProbabilities([-2.0, 3.0]), isFalse);
    });
  });

  group('normalisedEntropy', () {
    test('is ~0 for a one-hot distribution', () {
      expect(normalisedEntropy([1.0, 0.0, 0.0, 0.0]), closeTo(0.0, 1e-9));
    });
    test('is 1 for a uniform distribution', () {
      final n = 14;
      final uniform = List.filled(n, 1 / n);
      expect(normalisedEntropy(uniform), closeTo(1.0, 1e-9));
    });
  });

  group('interpretOutput — acceptance gate', () {
    test('accepts a confident single-class prediction', () {
      final r = interpretOutput(
          [8, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], labels);
      expect(r.accepted, isTrue);
      expect(r.topIndex, 0);
      expect(r.topLabel, 'Pattern 1');
      expect(r.confidence, greaterThan(0.9));
      expect(r.topK.length, 3);
    });

    test('accepts an already-softmaxed confident vector without re-softmaxing',
        () {
      final probs = [
        0.92, 0.01, 0.01, 0.01, 0.01, 0.005, 0.005, //
        0.005, 0.005, 0.005, 0.005, 0.005, 0.003, 0.002,
      ];
      final r = interpretOutput(probs, labels);
      expect(r.accepted, isTrue);
      expect(r.confidence, closeTo(0.92, 1e-6));
    });

    test('rejects a flat / uninformative output (lamp, tree, wall)', () {
      final flat = [
        0.1, 0.0, 0.2, 0.1, 0.0, 0.1, 0.0, //
        0.1, 0.2, 0.0, 0.1, 0.0, 0.1, 0.0,
      ];
      final r = interpretOutput(flat, labels);
      expect(r.accepted, isFalse);
      expect(r.rejectReasons, isNotEmpty);
    });

    test('rejects an ambiguous two-class output', () {
      final r = interpretOutput(
          [5, 4.8, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], labels);
      expect(r.accepted, isFalse);
      expect(r.rejectReasons, contains('ambiguous'));
    });

    test('honours custom thresholds', () {
      final vec = [3.2, 1.0, 0.5, 0.2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      // Default thresholds accept this moderate prediction...
      expect(interpretOutput(vec, labels).accepted, isTrue);
      // ...but a strict confidence floor rejects it.
      final strict = interpretOutput(vec, labels,
          thresholds: const ClassificationThresholds(minTopProb: 0.95));
      expect(strict.accepted, isFalse);
      expect(strict.rejectReasons, contains('low_confidence'));
    });
  });

  group('interpretOutput — labels', () {
    test('falls back to "Class N" when labels are missing', () {
      final r = interpretOutput([9.0, 0.0, 0.0], const []);
      expect(r.topLabel, 'Class 0');
    });

    test('reported confidence never exceeds 1', () {
      final rnd = math.Random(42);
      final vec = List.generate(14, (_) => rnd.nextDouble() * 10);
      final r = interpretOutput(vec, labels);
      expect(r.confidence, lessThanOrEqualTo(1.0));
    });
  });
}
