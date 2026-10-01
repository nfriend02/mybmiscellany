enum BmiGender { male, female, other }

class BmiResult {
  const BmiResult({
    required this.bmi,
    required this.category,
    required this.guidance,
    required this.targetKg,
    required this.healthyMinKg,
    required this.healthyMaxKg,
    required this.age,
    required this.ageBand,
  });

  final double bmi;
  final String category;
  final String guidance;
  final double targetKg;
  final double healthyMinKg;
  final double healthyMaxKg;
  final int age;
  final String ageBand;
}

BmiResult calculateBmi({
  required double heightCm,
  required double weightKg,
  required BmiGender gender,
  required int age,
}) {
  if (heightCm < 50 || heightCm > 260) {
    throw const FormatException('키는 50cm에서 260cm 사이로 입력해 주세요.');
  }
  if (weightKg < 10 || weightKg > 400) {
    throw const FormatException('몸무게는 10kg에서 400kg 사이로 입력해 주세요.');
  }
  if (age < 2 || age > 120) {
    throw const FormatException('나이는 2세에서 120세 사이로 입력해 주세요.');
  }
  final meters = heightCm / 100;
  final bmi = weightKg / (meters * meters);
  final adultIdeal = switch (gender) {
    BmiGender.male => 22.0,
    BmiGender.female => 21.0,
    BmiGender.other => 21.5,
  };
  final double low;
  final double high;
  final double idealBmi;
  final String ageBand;
  final String standard;
  if (age < 20) {
    low = 18.5;
    high = 24.9;
    idealBmi = adultIdeal;
    ageBand = '성장기';
    standard = '$age세는 성장기라 성인 WHO 수치를 참고만 합니다.';
  } else if (age >= 65) {
    low = 22;
    high = 27;
    idealBmi = switch (gender) {
      BmiGender.male => 23.0,
      BmiGender.female => 22.5,
      BmiGender.other => 23.0,
    };
    ageBand = '고령';
    standard = '$age세는 고령 참고 구간 BMI 22~27을 적용했습니다.';
  } else {
    low = 18.5;
    high = 24.9;
    idealBmi = adultIdeal;
    ageBand = '성인';
    standard = '$age세는 성인 WHO 기준을 적용했습니다.';
  }
  final target = idealBmi * meters * meters;
  final healthyMin = low * meters * meters;
  final healthyMax = high * meters * meters;
  final category = bmi < low
      ? '저체중'
      : bmi <= high
      ? '정상'
      : bmi < high + 5
      ? '과체중'
      : '비만';
  final diff = weightKg - target;
  final direction = diff > 0.4
      ? '${diff.toStringAsFixed(1)}kg 감량을 참고 목표로 잡아 보세요.'
      : diff < -0.4
      ? '${(-diff).toStringAsFixed(1)}kg 증량을 참고 목표로 잡아 보세요.'
      : '참고 목표 체중에 가깝습니다.';
  final guidance =
      '$standard BMI는 ${bmi.toStringAsFixed(1)}이며 $ageBand 기준 $category 구간입니다. '
      '참고 목표 체중은 ${target.toStringAsFixed(1)}kg (BMI ${idealBmi.toStringAsFixed(1)})이고, '
      '건강 범위는 ${healthyMin.toStringAsFixed(1)}~${healthyMax.toStringAsFixed(1)}kg입니다. $direction';
  return BmiResult(
    bmi: bmi,
    category: category,
    guidance: guidance,
    targetKg: target,
    healthyMinKg: healthyMin,
    healthyMaxKg: healthyMax,
    age: age,
    ageBand: ageBand,
  );
}

String genderLabel(BmiGender gender) {
  return switch (gender) {
    BmiGender.male => '남',
    BmiGender.female => '여',
    BmiGender.other => '기타',
  };
}
