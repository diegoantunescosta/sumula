# 🤖 Copilot Agents - Segurança & Qualidade Contínua

Este projeto está configurado com **Copilot Agents** para análise automática de segurança, testes e performance.

---

## 🎯 O Que É Feito Automaticamente

### 🔒 **Análise de Segurança** (Diária às 02:00 UTC)
```
✅ Auditoria de dependências (npm audit)
✅ Busca de secrets commitados
✅ Análise estática de código (SAST)
✅ Verificação de CORS, Auth, Rate Limiting
✅ Validação de inputs
```

### 🧪 **Análise de Testes** (Diária às 03:00 UTC)
```
✅ Relatório de cobertura de testes
✅ Identifica arquivos sem testes
✅ Recomenda testes para funções críticas
✅ Verifica E2E tests
```

### ⚡ **Análise de Performance** (Terças-feira às 04:00 UTC)
```
✅ Bundle size analysis
✅ N+1 query detection
✅ Database optimization
✅ Endpoint performance
✅ OWASP Top 10 check
```

---

## 🚀 Como Usar

### Via GitHub Web (Mais Fácil!)

1. **Vá para:** `https://github.com/diegoantunescosta/drive-of-dreams/agents`

2. **Clique em:** "New agent session"

3. **Cole uma tarefa:**
   ```
   "Implementar autenticação 2FA em login.ts"
   "Corrigir vulnerabilidade de SQL Injection em payment.js"
   "Adicionar testes para stripe-webhook.js"
   ```

4. **Aprove o plano** que o Copilot propõe

5. **Agents trabalham** e abrem uma PR automaticamente

---

### Via CLI

```bash
# Disparar análise de segurança
gh workflow run copilot-agents-analysis.yml \
  -f analysis_type=security

# Disparar análise de testes
gh workflow run copilot-agents-analysis.yml \
  -f analysis_type=tests

# Disparar todas as análises
gh workflow run copilot-agents-analysis.yml \
  -f analysis_type=all
```

---

### Via Issues/PRs com Labels

**Apenas crie uma issue ou PR com um destes labels:**

- 🔒 `security` → Análise de segurança
- 🧪 `test-coverage` → Análise de testes
- 🚀 `performance` → Análise de performance
- ♻️ `refactor` → Refatoração de código
- 📚 `documentation` → Atualizar docs

---

## 📊 Relatórios Gerados

Os relatórios são salvos em:

```
.audit-reports/           # Relatórios de segurança
.test-reports/            # Relatórios de testes
.performance-reports/     # Relatórios de performance
```

Você pode baixar na aba **Artifacts** de qualquer workflow run.

---

## 🔄 Workflow de um Agent

```
1. DISPARO
   ├─ Via schedule (automático)
   ├─ Via label de issue/PR
   └─ Via workflow_dispatch (manual)

2. ANÁLISE
   ├─ Executa scripts de análise
   ├─ Coleta dados do projeto
   └─ Gera relatório

3. DECISÃO
   ├─ Agent interpreta os dados
   ├─ Propõe melhorias
   └─ Cria plano de ação

4. EXECUÇÃO
   ├─ Agent cria branch
   ├─ Implementa mudanças
   ├─ Roda testes
   └─ Abre Pull Request

5. REVIEW
   ├─ Você revisa a PR
   ├─ Deixa comentários
   └─ Agent adapta-se aos seus comentários
```

---

## 📋 Projetos Monitorados

| Projeto | Repo | Status |
|---------|------|--------|
| MegaPack 3D (Drive of Dreams) | `drive-of-dreams` | 🔄 Ativo |
| SUMULA | `sumula` | 🔄 Ativo |
| SimuMed | `simumed` | 🔄 Ativo |
| 3D Costa | `3d-costa-projects` | 🔄 Ativo |

---

## 🎓 Exemplos de Tarefas

### Exemplo 1: Corrigir Vulnerabilidade
```
Título: "🔒 security"
Descrição: "
Vulnerabilidade encontrada:
- Arquivo: server/routes/payment.js
- Tipo: Possível SQL Injection em query de usuário
- Linha: ~45

Por favor, corrigir e criar testes.
"
```

### Exemplo 2: Aumentar Cobertura
```
Título: "🧪 test-coverage"
Descrição: "
Funções sem testes:
- stripeCheckout.js: createCheckoutSessionUrl()
- auth.js: hashPassword()
- db.js: getPurchasesByUserId()

Criar testes unitários e E2E.
"
```

### Exemplo 3: Otimizar Performance
```
Título: "🚀 performance"
Descrição: "
N+1 Query detectada:
- SELECT * FROM users em loop
- Deve usar batch query

Por favor, otimizar e medir performance.
"
```

---

## 🔐 Configuração Necessária

Os agents precisam de secrets configurados no GitHub:

```bash
# Já configurado ✅
TELEGRAM_TOKEN=${{ secrets.TELEGRAM_TOKEN }}
TELEGRAM_CHAT_ID=${{ secrets.TELEGRAM_CHAT_ID }}
```

---

## 📞 Notificações

Todos os eventos são notificados no Telegram:

```
🔒 Security Audit Concluído
🧪 Test Analysis Concluído
⚡ Performance Analysis Concluído
```

---

## 🎯 Próximos Passos

1. **Habilitar Copilot na organização** (GitHub Settings → Copilot)
2. **Criar primeiro agent session** (via `/agents`)
3. **Deixar rodar análises automáticas** (todo dia)
4. **Revisar PRs do Copilot** (e adaptar conforme necessário)

---

## 📚 Documentação

- [GitHub Copilot Agents](https://docs.github.com/copilot/responsible-use/copilot-coding-agent)
- [Copilot Cloud Agent](https://github.com/features/copilot)
- [GitHub Actions](https://github.com/features/actions)

---

**Criado em:** 2026-11-26  
**Última atualização:** 2026-11-26
