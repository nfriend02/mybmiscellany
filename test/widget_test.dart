import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybmiscellany/app/MybApp.dart';
import 'package:mybmiscellany/core/router/appRouter.dart';

void main() {
  testWidgets('home shows the game center and learning toolbox', (
    tester,
  ) async {
    await tester.pumpWidget(const MybApp());
    await tester.pump();

    expect(find.text('GAME CENTER'), findsOneWidget);
    expect(find.text('LEARNING TOOLBOX'), findsOneWidget);
    expect(find.text('Lucky Canon'), findsOneWidget);
    expect(find.text('BMI Calculator'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('desktop feature pages give text fields a material ancestor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MybApp());
    await tester.pump();
    appRouter.go('/lucky-canon');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
