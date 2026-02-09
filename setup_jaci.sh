#!/usr/bin/env bash
set -e

echo "=================================================="
echo " Setup de Ambiente JACI — MONAN_DAS"
echo "=================================================="
echo
echo "Este script vai configurar seu ambiente no JACI."
echo "Nada será apagado. Backups e rollback serão criados."
echo

read -rp "Deseja continuar? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || exit 0

echo
echo "Escolha o modo de instalação:"
echo "  1) Modo padrão (RECOMENDADO)"
echo "  2) Modo avançado (isolamento total do HOME)"
read -rp "Opção [1/2]: " mode

echo
echo "[INFO] Iniciando configuração..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/scripts/jaci_env_migrate.sh"

if [[ "$mode" == "2" ]]; then
  echo
  echo "[WARN] Modo avançado selecionado"
  read -rp "Tem certeza? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/scripts/jaci_home_router.sh"
  else
    echo "[INFO] Modo avançado cancelado"
  fi
fi

echo
echo "[OK] Ambiente configurado com sucesso!"
echo
echo "IMPORTANTE:"
echo "  1) Faça logout"
echo "  2) Conecte novamente ao JACI"
echo

