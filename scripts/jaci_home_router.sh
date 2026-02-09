#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# JACI HOME ROUTER
# Isola ambiente JACI e preserva HOME corporativo legado
# Safe by design: no deletes, only copy/rename/symlink
# ==============================================================================

TS=$(date +%Y%m%d_%H%M%S)
BACKUP_ROOT="$HOME/HOME_LEGACY_BACKUP"
BACKUP_DIR="$BACKUP_ROOT/$TS"
mkdir -p "$BACKUP_DIR"

log(){ echo "[INFO] $*"; }
warn(){ echo "[WARN] $*" >&2; }

# ------------------------------------------------------------------------------
# 1. Backup dos arquivos críticos
# ------------------------------------------------------------------------------
FILES=(
  .bash_profile
  .bash_login
  .bashrc
  .profile
  .condarc
)

log "Criando backup em $BACKUP_DIR"
for f in "${FILES[@]}"; do
  if [[ -e "$HOME/$f" ]]; then
    cp -a "$HOME/$f" "$BACKUP_DIR/$f"
    log "Backup: $f"
  fi
done

# Backup pesado (opcional, mas seguro)
for d in .config .ssh; do
  if [[ -e "$HOME/$d" ]]; then
    tar -C "$HOME" -cpf "$BACKUP_DIR/${d}.tar" "$d" 2>/dev/null || true
    log "Arquivado: $d"
  fi
done

# ------------------------------------------------------------------------------
# 2. Determinar legacy (.bashrc e .profile mais recentes)
# ------------------------------------------------------------------------------
find_latest() {
  ls -t "$@" 2>/dev/null | head -n 1 || true
}

LEGACY_BASHRC=$(find_latest "$HOME/.bashrc" "$HOME/.bashrc.legacy."*)
LEGACY_PROFILE=$(find_latest "$HOME/.profile" "$HOME/.profile.legacy."*)

if [[ -z "$LEGACY_BASHRC" || -z "$LEGACY_PROFILE" ]]; then
  warn "Nao foi possivel detectar legacy automaticamente."
  warn "Usando arquivos atuais como legacy."
  LEGACY_BASHRC="$HOME/.bashrc"
  LEGACY_PROFILE="$HOME/.profile"
fi

# ------------------------------------------------------------------------------
# 3. Congelar legacy (sem apagar)
# ------------------------------------------------------------------------------
freeze() {
  local f="$1"
  if [[ -e "$HOME/$f" ]]; then
    mv "$HOME/$f" "$HOME/$f.legacy.$TS"
    log "Congelado: $f -> $f.legacy.$TS"
  fi
}

freeze ".bashrc"
freeze ".profile"
freeze ".bash_login"
freeze ".bash_profile"

# ------------------------------------------------------------------------------
# 4. Criar links estaveis para legacy
# ------------------------------------------------------------------------------
ln -sfn "$LEGACY_BASHRC" "$HOME/.bashrc.legacy"
ln -sfn "$LEGACY_PROFILE" "$HOME/.profile.legacy"

log "Legacy fixado:"
log "  .bashrc.legacy -> $LEGACY_BASHRC"
log "  .profile.legacy -> $LEGACY_PROFILE"

# ------------------------------------------------------------------------------
# 5. Criar ambiente JACI limpo
# ------------------------------------------------------------------------------
cat > "$HOME/.profile.jaci" <<'EOP'
# ================= JACI PROFILE =================
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
EOP
chmod 700 "$HOME/.profile.jaci"

cat > "$HOME/.bashrc.jaci" <<'EOR'
# ================= JACI BASHRC =================
set -o noclobber

unset PYTHONPATH
unset LD_LIBRARY_PATH
export CONDA_AUTO_ACTIVATE_BASE=false

if command -v module >/dev/null 2>&1; then
  module purge || true
fi

PS1="[JACI:\h \W]\\$ "
alias ll='ls -lah'
EOR
chmod 700 "$HOME/.bashrc.jaci"

# ------------------------------------------------------------------------------
# 6. Criar bash_profile roteador
# ------------------------------------------------------------------------------
cat > "$HOME/.bash_profile" <<'EOB'
# ================= BASH PROFILE ROUTER =================
HOST=$(hostname -s)

if [[ "$HOST" == ian* || "$HOST" == jaci* ]]; then
  export JACI_ENV=1
  [[ -f "$HOME/.profile.jaci" ]] && . "$HOME/.profile.jaci"
  [[ -f "$HOME/.bashrc.jaci"  ]] && . "$HOME/.bashrc.jaci"
else
  export JACI_ENV=0
  [[ -f "$HOME/.profile.legacy" ]] && . "$HOME/.profile.legacy"
  [[ -f "$HOME/.bashrc.legacy"  ]] && . "$HOME/.bashrc.legacy"
fi
EOB
chmod 700 "$HOME/.bash_profile"

# ------------------------------------------------------------------------------
# 7. Criar rollback
# ------------------------------------------------------------------------------
ROLLBACK="$HOME/jaci_home_rollback_$TS.sh"
cat > "$ROLLBACK" <<EOF2
#!/usr/bin/env bash
set -euo pipefail
echo "[INFO] Rollback para estado anterior ($TS)"

cp -a "$BACKUP_DIR"/.bash* "$HOME/" 2>/dev/null || true
cp -a "$BACKUP_DIR"/.profile "$HOME/" 2>/dev/null || true
cp -a "$BACKUP_DIR"/.condarc "$HOME/" 2>/dev/null || true

echo "[INFO] Rollback concluido. Relogue."
EOF2
chmod 700 "$ROLLBACK"

log "Script concluido com sucesso."
log "Relogue para aplicar."
log "Rollback: bash $ROLLBACK"
