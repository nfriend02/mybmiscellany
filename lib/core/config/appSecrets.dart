class AppSecrets {
  static const openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );
  static const exchangeRateApiKey = String.fromEnvironment(
    'EXCHANGE_RATE_API_KEY',
  );
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const oauthClientId = String.fromEnvironment('OAuth_Client_ID');

  static bool get hasOpenWeather => openWeatherApiKey.isNotEmpty;
  static bool get hasExchangeRate => exchangeRateApiKey.isNotEmpty;
  static bool get hasGemini => geminiApiKey.isNotEmpty;
  static bool get hasOAuth => oauthClientId.isNotEmpty;
}
