# JACI — Quick Start (Grupo MONAN_DAS)

Este guia descreve o uso básico do ambiente JACI após a instalação.

---

## Login

```bash
ssh usuario@jaci.cptec.inpe.br
````

Após o login, você estará automaticamente no workspace:

```text
/p/projetos/monan_das/usuario
```

---

## Regras essenciais

* ❌ Não execute cargas pesadas nos login nodes
* ❌ Não trabalhe no `$HOME`
* ✅ Use `/p` para código, dados e execuções
* ✅ Use PBS para qualquer job

---

## Submissão básica (exemplo)

```bash
qsub run/job.pbs
```

---

## Se algo der errado

* Leia as mensagens `[WARN]` no terminal
* Verifique se está em `/p`
* Consulte `README.md`


