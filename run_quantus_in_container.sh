#!/usr/bin/env bash
set -euo pipefail

########## KONFIG ##########
Q_REWARDS="qzq5Ui4a7zSeFhNTmixuYBkUDC8oRQAN12fysXXK92LTzksHF"
Q_NAME="C03"
HOST_DIR_BASE="/root"
WORKERS_OVERRIDE=""
BOOTSTRAP_TARBALL=""
######## KONIEC KONFIG #####

HOST_DIR="${HOST_DIR_BASE}/quantus-${Q_NAME}"
CONTAINER="quantus-${Q_NAME}"
CHAIN_DIR="chain_data_dir"
IMAGE="ubuntu:24.04"

echo "🚀 Uruchamiam Quantus node + miner dla: ${Q_NAME}"

if ! command -v docker >/dev/null 2>&1; then
  apt update && apt install -y docker.io
  systemctl enable --now docker
fi

mkdir -p "${HOST_DIR}"

docker pull "${IMAGE}"
docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true

docker run -d --name "${CONTAINER}" \
  --restart unless-stopped \
  --network host \
  --ulimit nofile=1048576:1048576 \
  -v "${HOST_DIR}":/opt/quantus \
  -w /opt/quantus \
  "${IMAGE}" sleep infinity

docker exec -it "${CONTAINER}" bash -lc \
 'apt update && DEBIAN_FRONTEND=noninteractive apt install -y ca-certificates libstdc++6 libssl3 tmux curl wget jq psmisc gnupg'

docker exec -it "${CONTAINER}" bash -lc '
  chmod +x ./quantus-node 2>/dev/null || true
  chmod +x ./quantus-miner-linux-x86_64 2>/dev/null || true
  if [[ ! -x ./quantus-node || ! -x ./quantus-miner-linux-x86_64 ]]; then
    echo "❗ Brak ./quantus-node lub ./quantus-miner-linux-x86_64 w /opt/quantus"; exit 12
  fi
'

if [[ -n "${BOOTSTRAP_TARBALL}" && -f "${BOOTSTRAP_TARBALL}" ]]; then
  echo "📦 Import snapshot: ${BOOTSTRAP_TARBALL}"
  tar -xzf "${BOOTSTRAP_TARBALL}" -C "${HOST_DIR}"
fi

docker exec -it "${CONTAINER}" bash -lc \
 '[[ -f node-key ]] || ./quantus-node key generate-node-key --file node-key'

CPU_THREADS=$(nproc --all || echo 2)
if [[ -n "${WORKERS_OVERRIDE}" ]]; then
  WORKERS="${WORKERS_OVERRIDE}"
else
  if [[ "${CPU_THREADS}" -le 2 ]]; then WORKERS=1; else WORKERS=$((CPU_THREADS-1)); fi
fi
echo "🧠 CPU threads=${CPU_THREADS} → WORKERS=${WORKERS}"

docker exec -it "${CONTAINER}" bash -lc "
  tmux kill-session -t qnode-${Q_NAME} 2>/dev/null || true
  tmux new -d -s qnode-${Q_NAME} './quantus-node \
    --max-blocks-per-request 64 \
    --validator \
    --chain schrodinger \
    --sync full \
    --node-key-file node-key \
    --rewards-address ${Q_REWARDS} \
    --name ${Q_NAME} \
    --base-path ${CHAIN_DIR}'"

docker exec -it "${CONTAINER}" bash -lc "
  tmux kill-session -t qminer-${Q_NAME} 2>/dev/null || true
  tmux new -d -s qminer-${Q_NAME} 'nice -n 5 ./quantus-miner-linux-x86_64 \
    --workers ${WORKERS} \
    --engine cpu-montgomery'"

cat <<EOF

✅ Quantus uruchomiony (node + miner)

📛 Name: ${Q_NAME}
💸 Rewards: ${Q_REWARDS}
📁 Host dir: ${HOST_DIR}
🐳 Container: ${CONTAINER}

📊 Logi:
  docker exec -it ${CONTAINER} tmux attach -t qnode-${Q_NAME}
  docker exec -it ${CONTAINER} tmux attach -t qminer-${Q_NAME}

🔁 Autostart: restart unless-stopped
EOF
