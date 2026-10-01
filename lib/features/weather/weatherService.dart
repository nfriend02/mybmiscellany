import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/appSecrets.dart';

class WeatherReport {
  const WeatherReport({
    required this.city,
    required this.description,
    required this.tempC,
    required this.humidity,
    required this.windSpeed,
  });

  final String city;
  final String description;
  final double tempC;
  final int humidity;
  final double windSpeed;

  String get summary =>
      '$city · $description · ${tempC.toStringAsFixed(1)}°C · 습도 $humidity% · 바람 ${windSpeed.toStringAsFixed(1)}m/s';
}

Future<WeatherReport> fetchWeather(String city) async {
  final query = city.trim();
  if (query.isEmpty) {
    throw const FormatException('도시 이름을 입력해 주세요.');
  }
  if (!AppSecrets.hasOpenWeather) {
    throw const FormatException('OPENWEATHER_API_KEY가 설정되지 않았습니다.');
  }
  final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
    'q': query,
    'units': 'metric',
    'lang': 'kr',
    'appid': AppSecrets.openWeatherApiKey,
  });
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw const FormatException('도시를 찾지 못했습니다. 영문 이름을 사용해 주세요.');
  }
  return parseWeather(jsonDecode(response.body));
}

WeatherReport parseWeather(Object? json) {
  if (json is! Map) {
    throw const FormatException('날씨 응답을 읽지 못했습니다.');
  }
  final weather = json['weather'];
  final main = json['main'];
  final wind = json['wind'];
  if (weather is! List || weather.isEmpty || main is! Map) {
    throw const FormatException('날씨 응답을 읽지 못했습니다.');
  }
  final first = weather.first;
  final description = first is Map ? first['description'] : null;
  final temp = main['temp'];
  final humidity = main['humidity'];
  if (description is! String || temp is! num) {
    throw const FormatException('날씨 응답을 읽지 못했습니다.');
  }
  final city = json['name'];
  return WeatherReport(
    city: city is String && city.isNotEmpty ? city : '알 수 없는 도시',
    description: description,
    tempC: temp.toDouble(),
    humidity: humidity is num ? humidity.round() : 0,
    windSpeed: wind is Map && wind['speed'] is num
        ? (wind['speed'] as num).toDouble()
        : 0,
  );
}
