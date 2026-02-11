#!/usr/bin/env bash
# =====================================================================
# cleanup_runs.sh
#
# Limpeza segura de runs antigos no JACI
#
# Remove diretórios de execução antigos com base na data de último
# acesso/modificação, respeitando proteções explícitas.
#
# MODOS:
#   dry-run : apenas lista o que seria removido (default)
#   clean   : remove efetivamente os diretórios elegíveis
#
# PROTEÇÕES:
#   - Diretórios contendo o arquivo KEEP nunca são removidos
#   - Apenas diretórios até profundidade fixa (runs/<exp>/<run>)
#
# USO:
#   cleanup_runs.sh [dry-run|clean]
#
# VARIÁVEIS DE AMBIENTE:
#   DAYS_OLD     Idade mínima (em dias) para remoção (default: 60)
#   JACI_WORKDIR Diretório base do usuário no JACI (obrigatório)
#
# EXEMPLOS:
#   DAYS_OLD=30 cleanup_runs.sh dry-run
#   cleanup_runs.sh clean
#
# =====================================================================

set -euo pipefail

# ---------------------------------------------------------------------
# Configurações
# ---------------------------------------------------------------------
DAYS_OLD="${DAYS_OLD:-60}"
MODE="${1:-dry-run}"

: "${JACI_WORKDIR:?Variável JACI_WORKDIR não definida}"

RUNS_BASE="${JACI_WORKDIR}/runs"
NOW_EPOCH="$(date +%s)"

# ---------------------------------------------------------------------
# Logging padronizado
# ---------------------------------------------------------------------
log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*" >&2; }
log_err()  { echo "[ERROR] $*" >&2; }

# ---------------------------------------------------------------------
# Cabeçalho
# ---------------------------------------------------------------------
log_info "Limpeza de runs antigos"
log_info "Diretório base : ${RUNS_BASE}"
log_info "Idade mínima   : ${DAYS_OLD} dias"
log_info "Modo           : ${MODE}"
echo

# ---------------------------------------------------------------------
# Verificações básicas
# ---------------------------------------------------------------------
if [[ ! -d "${RUNS_BASE}" ]]; then
  log_err "Diretório não existe: ${RUNS_BASE}"
  exit 1
fi

if [[ "${MODE}" != "dry-run" && "${MODE}" != "clean" ]]; then
  log_err "Uso inválido. Use: cleanup_runs.sh [dry-run|clean]"
  exit 1
fi

# ---------------------------------------------------------------------
# Varredura controlada
# Estrutura esperada:
#   runs/<experimento>/<run>
# ---------------------------------------------------------------------
find "${RUNS_BASE}" -mindepth 2 -maxdepth 2 -type d | while read -r run_dir; do

  # ---------------------------------------------------------------
  # Proteção explícita
  # ---------------------------------------------------------------
  if [[ -f "${run_dir}/KEEP" ]]; then
    log_info "[KEEP] ${run_dir} (arquivo KEEP presente)"
    continue
  fi

  # ---------------------------------------------------------------
  # Cálculo da idade
  # Usa mtime para evitar dependência de atime (frequentemente desativado)
  # ---------------------------------------------------------------
  last_touch_epoch="$(stat -c %Y "${run_dir}")"
  age_days=$(( (NOW_EPOCH - last_touch_epoch) / 86400 ))

  if (( age_days < DAYS_OLD )); then
    continue
  fi

  # ---------------------------------------------------------------
  # Ação
  # ---------------------------------------------------------------
  if [[ "${MODE}" == "dry-run" ]]; then
    echo "[DRY] Removeria: ${run_dir} (${age_days} dias)"
  else
    echo "[DEL] Removendo : ${run_dir} (${age_days} dias)"
    rm -rf --one-file-system "${run_dir}"
  fi

done

echo
log_info "Limpeza concluída (modo: ${MODE})"

