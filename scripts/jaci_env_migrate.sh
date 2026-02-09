#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Jaci environment migration (SAFE)
# - never deletes anything; only copies/renames
# - creates isolated Jaci configs: .bash_profile, .profile.jaci, .bashrc.jaci
# - preserves previous configs as *.legacy.<timestamp>
# - creates rollback script
# -----------------------------------------------------------------------------

ts="$(date +%Y%m%d_%H%M%S)"
backup_dir="$HOME/HOME_LEGACY_BACKUP/$ts"
mkdir -p "$backup_dir"

log() { printf '[INFO] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }

# Files we may touch
files_to_backup=(
  ".bash_profile"
  ".bash_login"
  ".bashrc"
  ".profile"
  ".condarc"
)

log "Backup dir: $backup_dir"
for f in "${files_to_backup[@]}"; do
  if [[ -e "$HOME/$f" ]]; then
    log "Backing up $f"
    cp -a "$HOME/$f" "$backup_dir/$f"
  fi
done

# Also backup these (can be big; use tar for metadata)
extra_backup=(".config" ".ssh")
for d in "${extra_backup[@]}"; do
  if [[ -e "$HOME/$d" ]]; then
    log "Archiving $d"
    tar -C "$HOME" -cpf "$backup_dir/${d//\//_}.tar" "$d" 2>/dev/null || true
  fi
done

# Helper: rename a file to legacy if it exists
rename_legacy() {
  local f="$1"
  if [[ -e "$HOME/$f" ]]; then
    local new="$HOME/${f}.legacy.${ts}"
    log "Renaming $f -> $(basename "$new")"
    mv "$HOME/$f" "$new"
  fi
}

# We will control login using .bash_profile
# Preserve old ones instead of deleting
rename_legacy ".bash_profile"
rename_legacy ".bash_login"

# Preserve the old bashrc/profile so Jaci doesn't inherit them automatically
rename_legacy ".bashrc"
rename_legacy ".profile"

# Create minimal, safe Jaci profile/bashrc
log "Creating .profile.jaci"
cat > "$HOME/.profile.jaci" <<'EOP'
# ============================================================
# Jaci profile (minimal, safe)
# ============================================================

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Keep PATH/LD_LIBRARY_PATH controlled by modules inside .bashrc.jaci.
# Avoid exporting custom PATH here.
EOP
chmod 700 "$HOME/.profile.jaci"

log "Creating .bashrc.jaci"
cat > "$HOME/.bashrc.jaci" <<'EOR'
# ============================================================
# Jaci bashrc (clean + reproducible)
# ============================================================

# Safer shell defaults
set -o noclobber

# Do not auto-activate Conda base (if conda becomes available later)
export CONDA_AUTO_ACTIVATE_BASE=false

# Clean dangerous inherited variables (common source of silent breakages)
unset PYTHONPATH
unset LD_LIBRARY_PATH

# Modules: start clean
if command -v module >/dev/null 2>&1; then
  module purge || true
fi

# Helpful prompt: always know you're on Jaci
PS1="[JACI:\h \W]\\$ "

# Convenience aliases (optional)
alias ll='ls -lah'
EOR
chmod 700 "$HOME/.bashrc.jaci"

log "Creating .bash_profile (controller)"
cat > "$HOME/.bash_profile" <<'EOB'
# ============================================================
# .bash_profile - environment controller
# ============================================================

HOSTNAME=$(hostname -s)

# Jaci environment (login nodes ian* and possibly jaci*)
if [[ $HOSTNAME == ian* ]] || [[ $HOSTNAME == jaci* ]]; then
  export JACI_ENV=1
  [[ -f "$HOME/.profile.jaci" ]] && . "$HOME/.profile.jaci"
  [[ -f "$HOME/.bashrc.jaci"  ]] && . "$HOME/.bashrc.jaci"
else
  # Non-Jaci environments: attempt to load legacy configs if present.
  # You can later point these to the right files for the corporate environment.
  export JACI_ENV=0
  for f in "$HOME/.profile.legacy" "$HOME/.profile.legacy."*; do
    [[ -f "$f" ]] && . "$f" && break
  done
  for f in "$HOME/.bashrc.legacy" "$HOME/.bashrc.legacy."*; do
    [[ -f "$f" ]] && . "$f" && break
  done
fi
EOB
chmod 700 "$HOME/.bash_profile"

# Create rollback script
rollback="$HOME/jaci_env_rollback_${ts}.sh"
log "Creating rollback script: $(basename "$rollback")"
cat > "$rollback" <<EOF2
#!/usr/bin/env bash
set -euo pipefail

ts="$ts"
echo "[INFO] Rolling back Jaci env changes from $ts"

# Restore originals from backup directory
backup_dir="$backup_dir"

restore() {
  local f="\$1"
  if [[ -f "\$backup_dir/\$f" ]]; then
    echo "[INFO] Restoring \$f"
    cp -a "\$backup_dir/\$f" "\$HOME/\$f"
  fi
}

restore ".bash_profile"
restore ".bash_login"
restore ".bashrc"
restore ".profile"
restore ".condarc"

echo "[INFO] Rollback done. Re-login to apply."
EOF2
chmod 700 "$rollback"

log "Done."
log "Next: exit and SSH again to apply the new clean Jaci environment."
log "If you need to rollback: bash $rollback"
