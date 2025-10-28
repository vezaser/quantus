#!/usr/bin/env bash
set -euo pipefail

SNAP_TARBALL="${1:-/root/bootstrap-quantus-schrodinger.tar.gz}"  # ścieżka do .tar.gz
SNAP_SHA256="${2:-}"                                            # opcjonalnie: .sha256
TARGET_DIR="${3:-/root/quantus-C02}"                             # gdzie masz binarki i ma być chain_data_dir

[[ -f "${SNAP_TARBALL}" ]] || { echo "❗ Brak pliku: ${SNAP_TARBALL}"; exit 20; }
mkdir -p "${TARGET_DIR}"

if [[ -n "${SNAP_SHA256}" ]]; then
  [[ -f "${SNAP_SHA256}" ]] || { echo "❗ Brak pliku SHA256: ${SNAP_SHA256}"; exit 21; }
  echo "🔎 Weryfikuję sumę kontrolną..."
  (cd "$(dirname "${SNAP_TARBALL}")" && sha256sum -c "${SNAP_SHA256}")
fi

echo "📦 Rozpakowuję snapshot do: ${TARGET_DIR}"
tar -xzf "${SNAP_TARBALL}" -C "${TARGET_DIR}"

echo "✅ Import zakończony. Struktura:"
echo "   ${TARGET_DIR}/chain_data_dir/chains/schrodinger/{db,keystore,network}"
echo
echo "➡️  Teraz odpal swój skrypt startowy (run-quantus-...sh)."
echo "    Pamiętaj: nowy node wygeneruje własny node-key (nie kopiuj go z innego serwera)."
