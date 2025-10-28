#!/usr/bin/env bash
set -euo pipefail

# ── USTAWIENIA (zmień jeśli chcesz) ────────────────────────────────────────────
SRC_DIR="${1:-/root/quantus}"        # katalog z chain_data_dir
OUT_DIR="${2:-/root}"                # gdzie zapisać snapshot (.tar.gz)
CONTAINER_OVERRIDE="${3:-}"          # opcjonalnie: nazwa kontenera, np. "quantus-C01"
CHAIN_SUBDIR="chain_data_dir"
SNAP_PREFIX="bootstrap-quantus-schrodinger"
DATESTAMP="$(date +%Y%m%d-%H%M%S)"
TARBALL="${OUT_DIR}/${SNAP_PREFIX}-${DATESTAMP}.tar.gz"
SHAFILE="${TARBALL}.sha256"
# ───────────────────────────────────────────────────────────────────────────────

echo "📁 SRC_DIR=${SRC_DIR}"
echo "📦 OUT_DIR=${OUT_DIR}"
echo "🔗 CHAIN_SUBDIR=${CHAIN_SUBDIR}"
echo

# 0) Wstępne kontrole
[[ -d "${SRC_DIR}/${CHAIN_SUBDIR}" ]] || { echo "❗ Brak ${SRC_DIR}/${CHAIN_SUBDIR}"; exit 10; }

if command -v docker >/dev/null 2>&1; then
  if [[ -n "${CONTAINER_OVERRIDE}" ]]; then
    CONTAINER="${CONTAINER_OVERRIDE}"
  else
    # Spróbuj wykryć pierwszy kontener zaczynający się od 'quantus'
    CONTAINER="$(docker ps --format '{{.Names}}' | grep -E '^quantus' | head -n1 || true)"
  fi
else
  CONTAINER=""
fi

if [[ -n "${CONTAINER}" ]]; then
  echo "🐳 Wykryto kontener: ${CONTAINER}"
else
  echo "ℹ️  Nie wykryto działającego kontenera Quantus (to nie problem)."
fi

mkdir -p "${OUT_DIR}"

# 1) Stop (na czas pakowania)
if [[ -n "${CONTAINER}" ]]; then
  echo "⏸️  Zatrzymuję kontener na czas pakowania..."
  docker stop "${CONTAINER}" >/dev/null
fi

# 2) Pakowanie
echo "🗜️  Tworzę snapshot: ${TARBALL}"
tar -C "${SRC_DIR}" -czf "${TARBALL}" "${CHAIN_SUBDIR}"

# 3) Start
if [[ -n "${CONTAINER}" ]]; then
  echo "▶️  Ponownie uruchamiam kontener..."
  docker start "${CONTAINER}" >/dev/null
fi

# 4) Suma kontrolna + info
sha256sum "${TARBALL}" | tee "${SHAFILE}" >/dev/null

SIZE_HUMAN=$(du -h "${TARBALL}" | awk '{print $1}')
echo
echo "✅ Gotowe!"
echo "   Plik: ${TARBALL}  (${SIZE_HUMAN})"
echo "   SHA:  $(cut -d' ' -f1 "${SHAFILE}")"
echo
echo "📤 Skopiuj na nowy serwer (przykład):"
echo "   scp ${TARBALL} root@NOWY_NODE_IP:/root/"
echo "   scp ${SHAFILE} root@NOWY_NODE_IP:/root/"
echo
echo "🛡️  Uwaga: NIE kopiuj pliku node-key między maszynami."
