import 'package:cyberskin_app/app/floating_control_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FloatingControlController controller;
  late Route<void> home;
  late Route<void> detail;
  const size = Size(126, 68);
  const bounds = Rect.fromLTWH(0, 100, 402, 660);
  setUp(() {
    controller = FloatingControlController();
    home = MaterialPageRoute<void>(builder: (_) => const SizedBox());
    detail = MaterialPageRoute<void>(builder: (_) => const SizedBox());
  });

  test('fixed pages dock and reject dragging', () {
    controller.activatePage(home, nextPolicy: FloatingControlPolicy.fixed);
    controller.reportPageBounds(home, bounds);
    expect(controller.targetFor(size), const Offset(252, 680));
    controller.startDrag(const Offset(70, 180));
    controller.dragBy(const Offset(20, 20));
    expect(controller.draggedPosition.value, isNull);
  });

  test('secondary pages retain position, home clears it', () {
    controller.activatePage(
      detail,
      nextPolicy: FloatingControlPolicy.draggable,
    );
    controller.reportPageBounds(detail, bounds);
    controller.startDrag(const Offset(252, 680));
    controller.dragBy(const Offset(-100, -180));
    controller.endDrag();
    expect(controller.targetFor(size), const Offset(152, 500));
    final another = MaterialPageRoute<void>(builder: (_) => const SizedBox());
    controller.activatePage(
      another,
      nextPolicy: FloatingControlPolicy.draggable,
    );
    controller.reportPageBounds(another, bounds);
    expect(controller.targetFor(size), const Offset(152, 500));
    controller.activatePage(
      home,
      nextPolicy: FloatingControlPolicy.fixed,
      resetPosition: true,
    );
    controller.reportPageBounds(home, bounds);
    expect(controller.draggedPosition.value, isNull);
    controller.activatePage(
      detail,
      nextPolicy: FloatingControlPolicy.draggable,
    );
    expect(controller.targetFor(size), const Offset(252, 680));
  });

  test(
    'clamps drag and geometry changes; inactive pages cannot overwrite bounds',
    () {
      controller.activatePage(
        detail,
        nextPolicy: FloatingControlPolicy.draggable,
      );
      controller.reportPageBounds(detail, bounds);
      controller.startDrag(const Offset(252, 680));
      controller.dragBy(const Offset(5000, -5000));
      expect(controller.targetFor(size), const Offset(252, 112));
      controller.dragBy(const Offset(0, 5000));
      controller.reportPageBounds(
        detail,
        const Rect.fromLTWH(0, 100, 320, 300),
      );
      expect(controller.draggedPosition.value, const Offset(170, 320));
      controller.reportPageBounds(home, bounds);
      expect(
        controller.bodyBounds.value,
        const Rect.fromLTWH(0, 100, 320, 300),
      );
      controller.updateControlSize(const Size(220, 110));
      expect(controller.draggedPosition.value, const Offset(76, 278));
    },
  );
}
