#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  flutter_home="${HOME}/flutter"
  if [[ ! -x "${flutter_home}/bin/flutter" ]]; then
    git clone https://github.com/flutter/flutter.git \
      --depth 1 \
      --branch 3.47.3 \
      "${flutter_home}"
  fi
  export PATH="${flutter_home}/bin:${PATH}"
fi

flutter config --no-analytics --enable-web
flutter precache --web
flutter pub get
flutter build web --release \
  --dart-define="OPENWEATHER_API_KEY=${OPENWEATHER_API_KEY:-}" \
  --dart-define="EXCHANGE_RATE_API_KEY=${EXCHANGE_RATE_API_KEY:-}" \
  --dart-define="GEMINI_API_KEY=${GEMINI_API_KEY:-}" \
  --dart-define="OAuth_Client_ID=${OAuth_Client_ID:-}"
