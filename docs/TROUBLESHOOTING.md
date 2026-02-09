# JACI — Troubleshooting

## Estou no HOME e recebo warnings

Isso é esperado.

Use:

```bash
cd
````

para voltar ao workspace JACI.

---

## Prompt não aparece colorido

Verifique:

```bash
echo $JACI_ENV
```

Se não for `1`, o `.bashrc.jaci` não foi carregado.

---

## Quebrei meu ambiente

Use o rollback mais recente no seu HOME:

```bash
ls jaci_*rollback*.sh
bash jaci_env_rollback_YYYYMMDD_HHMMSS.sh
```

Nada é apagado permanentemente.

