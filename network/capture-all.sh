#!/usr/bin/env bash
set -eu

# capture-all.sh — per-interface tcpdump to separate files
# Usage:
#   sudo ./capture-all.sh            # capture everything
#   sudo ./capture-all.sh --exclude-ssh  # exclude TCP/22 (SSH)

set -euo pipefail

BPF=""
if [[ "${1:-}" == "--exclude-ssh" ]]; then
  BPF="not tcp port 22"
fi

TS="$(date +%Y%m%d-%H%M%S)"
# All UP interfaces (names only; strip possible '@' peer suffixes)
IFACES=$(ip -o link show up | awk -F': ' '{print $2}' | cut -d@ -f1)

if [[ -z "${IFACES}" ]]; then
  echo "No UP interfaces found." >&2
  exit 1
fi

echo "Starting captures at ${TS}"
echo "Interfaces: ${IFACES}"
[[ -n "${BPF}" ]] && echo "Filter: ${BPF}"

pids=()

cleanup() {
  echo -e "\nStopping captures..."
  for p in "${pids[@]}"; do
    kill "$p" 2>/dev/null || true
    wait "$p" 2>/dev/null || true
  done
  echo "Done."
}

trap cleanup INT TERM

for IF in ${IFACES}; do
  OUT="${IF}-${TS}.pcap"
  echo "  -> ${IF} -> ${OUT}"
  # -s 0 full packets, -n no DNS. Adjust/add flags if you like.
  tcpdump -i "${IF}" -s 0 -n -w "${OUT}" ${BPF:+${BPF}} &
  pids+=($!)
done

# If any tcpdump exits, stop the rest.
wait -n || true
cleanup
