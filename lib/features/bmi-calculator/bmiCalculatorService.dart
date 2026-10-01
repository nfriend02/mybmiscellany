enum BmiGender { male, female, other }

class BmiResult {
  const BmiResult({
    required this.bmi,
    required this.category,
    required this.guidance,
    required this.targetKg,
    required this.healthyMinKg,
    required this.healthyMaxKg,
  });

  final double bmi;
  final String category;
  final String guidance;
  final double targetKg;
  final double healthyMinKg;
  final double healthyMaxKg;
}

BmiResult calculateBmi({
  required double heightCm,
  required double weightKg,
  required BmiGender gender,
}) {
  if (heightCm < 50 || heightCm > 260) {
    throw const FormatException('키는 50cm에서 260cm 사이로 입력해 주세요.');
  }
  if (weightKg < 10 || weightKg > 400) {
    throw const FormatException('몸무게는 10kg에서 400kg 사이로 입력해 주세요.');
  }
  final meters = heightCm / 100;
  final bmi = weightKg / (meters * meters);
  final idealBmi = switch (gender) {
    BmiGender.male => 22.0,
    BmiGender.female => 21.0,
    BmiGender.other => 21.5,
  };
  final target = idealBmi * meters * meters;
  final healthyMin = 18.5 * meters * meters;
  final healthyMax = 24.9 * meters * meters;
  final category = bmi < 18.5
      ? '저체중'
      : bmi < 25
      ? '정상'
      : bmi < 30
      ? '과체중'
      : '비만';
  final diff = weightKg - target;
  final direction = diff > 0.4
      ? '${diff.toStringAsFixed(1)}kg 감량을 참고 목표로 잡아 보세요.'
      : diff < -0.4
      ? '${(-diff).toStringAsFixed(1)}kg 증량을 참고 목표로 잡아 보세요.'
      : '참고 목표 체중에 가깝습니다.';
  final guidance =
      'WHO 기준 BMI는 ${bmi.toStringAsFixed(1)}이며 $category 구간입니다. '
      '참고 목표 체중은 ${target.toStringAsFixed(1)}kg (BMI ${idealBmi.toStringAsFixed(1)})이고, '
      '건강 범위는 ${healthyMin.toStringAsFixed(1)}~${healthyMax.toStringAsFixed(1)}kg입니다. $direction';
  return BmiResult(
    bmi: bmi,
    category: category,
    guidance: guidance,
    targetKg: target,
    healthyMinKg: healthyMin,
    healthyMaxKg: healthyMax,
  );
}

String genderLabel(BmiGender gender) {
  return switch (gender) {
    BmiGender.male => '남',
    BmiGender.female => '여',
    BmiGender.other => '기타',
  };
}
