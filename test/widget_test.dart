import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybmiscellany/app/MybApp.dart';

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
}
