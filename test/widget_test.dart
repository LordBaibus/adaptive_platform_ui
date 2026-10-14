import 'dart:ui';

import 'package:adaptive_ui/core/device_layout.dart';
import 'package:adaptive_ui/core/ph_time.dart';
import 'package:adaptive_ui/models/task.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DeviceLayout> _layoutFor(
  WidgetTester tester, {
  required Size size,
  List<DisplayFeature> features = const [],
}) async {
  late DeviceLayout layout;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, displayFeatures: features),
      child: Builder(
        builder: (context) {
          layout = DeviceLayout.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return layout;
}

void main() {
  group('DeviceLayout', () {
    testWidgets('phone is a single pane', (tester) async {
      final layout = await _layoutFor(tester, size: const Size(400, 800));
      expect(layout.paneMode, PaneMode.single);
      expect(layout.isFoldable, isFalse);
    });

    testWidgets('tablet uses two panes', (tester) async {
      final layout = await _layoutFor(tester, size: const Size(900, 1200));
      expect(layout.paneMode, PaneMode.sideBySide);
    });

    testWidgets('vertical hinge splits side by side', (tester) async {
      final layout = await _layoutFor(
        tester,
        size: const Size(1100, 800),
        features: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(545, 0, 10, 800),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(layout.isFoldable, isTrue);
      expect(layout.isSeparating, isTrue);
      expect(layout.paneMode, PaneMode.sideBySide);
    });

    testWidgets('horizontal half-open fold stacks panes', (tester) async {
      final layout = await _layoutFor(
        tester,
        size: const Size(800, 1100),
        features: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(0, 550, 800, 0),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(layout.paneMode, PaneMode.stacked);
    });

    testWidgets('flat unfolded foldable is foldable but not separating',
        (tester) async {
      final layout = await _layoutFor(
        tester,
        size: const Size(840, 900),
        features: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(420, 0, 0, 900),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
      );
      expect(layout.isFoldable, isTrue);
      expect(layout.isSeparating, isFalse);
      expect(layout.paneMode, PaneMode.sideBySide);
    });
  });

  test('Task.fromMap parses a Supabase row', () {
    final task = Task.fromMap({
      'id': 'abc',
      'title': 'Web App UI Design',
      'description': null,
      'status': 'in_process',
      'progress': 70,
      'estimated_hours': 50,
      'due_date': '2026-10-14',
      'category': 'Web Design',
      'is_urgent': true,
      'created_at': '2026-10-14T02:36:41.715Z',
    });
    expect(task.title, 'Web App UI Design');
    expect(task.description, '');
    expect(task.status, TaskStatus.inProcess);
    expect(task.spentHours, 35);
    expect(task.isUrgent, isTrue);
    expect(task.toMap()['due_date'], '2026-10-14');
    expect(task.toMap()['status'], 'in_process');
  });

  test('toPhTime converts a UTC instant to Philippine time (UTC+8)', () {
    final ph = toPhTime(DateTime.utc(2026, 10, 14, 20, 30));
    expect(ph, DateTime(2026, 10, 15, 4, 30));
  });

  test('phToday has no time part', () {
    final today = phToday();
    expect(today.hour, 0);
    expect(today.minute, 0);
  });
}
