#!/bin/bash
# 🧪 TEST AUTOMATION - Análise de cobertura e geração de testes
# Executado pelo Copilot Agent

set -e

echo "🧪 INICIANDO ANÁLISE DE TESTES..."
mkdir -p .test-reports
REPORT_DATE=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE=".test-reports/coverage-$REPORT_DATE.md"

{
  echo "# 🧪 Relatório de Testes e Cobertura"
  echo "**Data:** $(date)"
  echo ""
  
  # 1. VERIFICAR FRAMEWORK DE TESTES
  echo "## 1️⃣ Setup de Testes"
  echo ""
  
  if [ -f "package.json" ]; then
    echo "### Frameworks detectados:"
    echo "\`\`\`"
    grep -E "jest|vitest|mocha|chai|cypress|playwright" package.json | head -5 || echo "Nenhum framework de testes padrão detectado"
    echo "\`\`\`"
    echo ""
  fi
  
  # 2. RODAR TESTES EXISTENTES
  echo "## 2️⃣ Executar Testes"
  echo ""
  
  if npm test -- --version 2>/dev/null; then
    echo "### Teste Unit"
    echo "\`\`\`"
    npm test -- --passWithNoTests --coverage --coverageReporters=json 2>&1 | tail -20 || true
    echo "\`\`\`"
    echo ""
  fi
  
  # 3. ANALISAR COBERTURA
  echo "## 3️⃣ Análise de Cobertura"
  echo ""
  
  if [ -f "coverage/coverage-summary.json" ]; then
    echo "✅ Cobertura detectada"
    echo "\`\`\`json"
    cat coverage/coverage-summary.json | jq '.total' 2>/dev/null || cat coverage/coverage-summary.json
    echo "\`\`\`"
    echo ""
    
    echo "### Arquivos com baixa cobertura (<80%):"
    echo "\`\`\`"
    find coverage -name "coverage-summary.json" -exec cat {} \; | jq '.[] | select(.lines.pct < 80) | {file: .file, lines: .lines.pct, statements: .statements.pct}' 2>/dev/null | head -10 || echo "Nenhum arquivo com cobertura baixa"
    echo "\`\`\`"
  else
    echo "⚠️ Nenhum relatório de cobertura encontrado"
    echo ""
    echo "**Recomendação:** Executar:"
    echo "\`\`\`bash"
    echo "npm test -- --coverage"
    echo "\`\`\`"
  fi
  echo ""
  
  # 4. IDENTIFICAR ARQUIVOS SEM TESTES
  echo "## 4️⃣ Arquivos Críticos Sem Testes"
  echo ""
  
  CRITICAL_FILES=(
    "server/routes/payment.js"
    "server/routes/auth.js"
    "server/routes/stripe-webhook.js"
    "server/db.js"
    "src/lib/api.ts"
    "src/hooks/use-stripe-checkout.ts"
  )
  
  echo "### Arquivos críticos a testar:"
  echo "\`\`\`"
  for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
      TEST_FILE="${file%.*}.test.${file##*.}"
      if [ -f "$TEST_FILE" ]; then
        echo "✅ $file (teste existe: $TEST_FILE)"
      else
        echo "❌ $file (SEM TESTES)"
      fi
    fi
  done
  echo "\`\`\`"
  echo ""
  
  # 5. RECOMENDAÇÕES DE TESTES
  echo "## 5️⃣ Recomendações"
  echo ""
  echo "### Testes que devem ser criados:"
  echo ""
  echo "#### Unit Tests"
  echo "- [ ] `payment.js` - Testar criação de checkout"
  echo "- [ ] `auth.js` - Testar autenticação e token JWT"
  echo "- [ ] `db.js` - Testar queries e migrations"
  echo ""
  
  echo "#### Integration Tests"
  echo "- [ ] Fluxo de pagamento (checkout → webhook → confirmação)"
  echo "- [ ] Autenticação (login → token → acesso protegido)"
  echo "- [ ] Download de arquivos (após pagamento)"
  echo ""
  
  echo "#### E2E Tests"
  echo "- [ ] Usuário completa compra do início ao fim"
  echo "- [ ] Usuário recebe email de confirmação"
  echo "- [ ] Usuário consegue fazer download"
  echo ""
  
  echo "#### Security Tests"
  echo "- [ ] SQL Injection em inputs"
  echo "- [ ] XSS em campos dinâmicos"
  echo "- [ ] CSRF em forms"
  echo "- [ ] Rate limiting no login"
  echo ""
  
  # 6. PERFORMANCE TESTS
  echo "## 6️⃣ Testes de Performance"
  echo ""
  echo "### Endpoints críticos a testar:"
  echo "\`\`\`"
  echo "POST /api/checkout - Criar sessão Stripe"
  echo "POST /api/auth/login - Autenticação"
  echo "GET /api/recent-purchases - Listar compras"
  echo "POST /webhook/stripe - Processar webhook"
  echo "\`\`\`"
  echo ""
  
  echo "**Target:** Tempo de resposta < 500ms, P95 < 1s"
  echo ""
  
  # 7. CYPRESS/PLAYWRIGHT
  echo "## 7️⃣ Testes E2E (Cypress/Playwright)"
  echo ""
  if [ -d "cypress" ] || [ -d "tests" ]; then
    echo "✅ Pasta de testes detectada"
  else
    echo "⚠️ Nenhuma pasta de testes E2E encontrada"
    echo ""
    echo "**Sugestão:** Criar em `cypress/e2e/`"
    echo "```"
    echo "cypress/e2e/checkout.cy.ts"
    echo "cypress/e2e/auth.cy.ts"
    echo "cypress/e2e/download.cy.ts"
    echo "```"
  fi
  echo ""
  
  # 8. RESUMO
  echo "## 📊 Resumo"
  echo ""
  echo "| Item | Status |"
  echo "|------|--------|"
  echo "| Framework detectado | ⚠️ Verificar |"
  echo "| Testes rodam | ⚠️ Verificar |"
  echo "| Cobertura | ⚠️ Verificar |"
  echo "| Testes críticos | ❌ Implementar |"
  echo "| E2E tests | ⚠️ Verificar |"
  echo ""
  
  echo "---"
  echo "**Próximos passos:**"
  echo "1. Instalar framework (Jest/Vitest)"
  echo "2. Criar testes unitários para funções críticas"
  echo "3. Criar testes de integração"
  echo "4. Configurar Cypress para E2E"
  echo "5. Adicionar CI/CD para rodar testes"
  
} | tee "$REPORT_FILE"

echo ""
echo "✅ Relatório salvo em: $REPORT_FILE"
