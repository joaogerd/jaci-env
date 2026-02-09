# Ambiente JACI — Grupo MONAN_DAS

Este repositório padroniza o **ambiente de trabalho no supercomputador JACI (CPTEC/INPE)**  
para os membros do grupo **MONAN_DAS**, garantindo:

- isolamento entre HOME corporativo e workspace HPC
- redução de erros operacionais
- ambiente previsível e reversível
- facilidade de replicação entre usuários

Nada aqui remove arquivos do usuário.  
**Tudo possui backup e rollback automático.**

---

## 📁 Estrutura do Ambiente

### HOME real (corporativo)
- `/home2/usuario`
- usado apenas para:
  - configuração
  - SSH keys
  - scripts leves

### Workspace JACI (trabalho real)
- `/p/projetos/monan_das/usuario`
- **todo código, dados, jobs e ambientes**
- acessível pelos compute nodes

---

## 🚀 Instalação Rápida (Recomendada)

```bash
git clone https://github.com/joaogerd/jaci-env.git
cd jaci-env
bash setup_jaci.sh
````

Após isso:

```bash
exit
ssh usuario@jaci.cptec.inpe.br
```

---

## 🧠 Modos de Instalação

### 🔹 Modo padrão (seguro)

* Limpa o ambiente do JACI
* Preserva todo o HOME legado
* Cria `.bashrc.jaci`
* Configura workspace em `/p`

👉 **Recomendado para a maioria dos usuários**

### 🔹 Modo avançado (isolamento total)

* Congela HOME legado
* Evita qualquer mistura de ambientes
* Recomendado apenas para usuários experientes

---

## 🔁 Rollback

Cada etapa gera um script de rollback automático:

```bash
bash ~/jaci_env_rollback_YYYYMMDD_HHMMSS.sh
```

Rollback é:

* seguro
* independente
* reversível

---

## ⚠️ Requisitos

* Acesso ao JACI
* Projeto válido em `/p/projetos/monan_das`
* Bash (shell padrão)

---

## 📌 Boas práticas no JACI

* ❌ Não execute cargas pesadas no login
* ❌ Não rode jobs a partir do `$HOME`
* ✅ Use PBS sempre
* ✅ Trabalhe em `/p`
* ✅ Separe ambientes (conda/spack)

---

## 📞 Suporte

Em caso de dúvida:

* consulte este repositório
* **não saia editando `.bashrc` manualmente**

