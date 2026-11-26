#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_bin="${FLUTTER_BIN:-flutter}"
api_origin="${SUMULA_API_URL:-https://sumula.costaprojects.online}"
if [[ "$api_origin" != https://* ]]; then
  echo 'A versão de publicação exige uma API HTTPS.' >&2
  exit 1
fi
if [[ ! -f "$project_dir/flutter_app/android/key.properties" ]]; then
  echo 'Configure a chave de upload em flutter_app/android/key.properties.' >&2
  exit 1
fi
cd "$project_dir/flutter_app"
"$flutter_bin" build appbundle --release \
  --dart-define="API_BASE_URL=$api_origin" \
  --dart-define=PLAY_STORE_BUILD=true \
  --build-name="${SUMULA_VERSION_NAME:-1.0.0}" \
  --build-number="${SUMULA_VERSION_CODE:-1}"
mkdir -p "$project_dir/release/play-store"
cp build/app/outputs/bundle/release/app-release.aab "$project_dir/release/play-store/sumula-${SUMULA_VERSION_NAME:-1.0.0}-${SUMULA_VERSION_CODE:-1}.aab"
cd "$project_dir/release/play-store"
sha256sum "sumula-${SUMULA_VERSION_NAME:-1.0.0}-${SUMULA_VERSION_CODE:-1}.aab" > SHA256SUMS.txt
echo 'Pacote Android gerado em release/play-store.'
