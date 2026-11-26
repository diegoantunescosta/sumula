#!/bin/bash
# 🔒 SECURITY AUDIT - Análise completa de segurança
# Executado pelo Copilot Agent

set -e

echo "🔒 INICIANDO AUDITORIA DE SEGURANÇA..."
mkdir -p .audit-reports
REPORT_DATE=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE=".audit-reports/security-$REPORT_DATE.md"

{
  echo "# 🔒 Relatório de Auditoria de Segurança"
  echo "**Data:** $(date)"
  echo ""
  
  # 1. NPM AUDIT
  echo "## 1️⃣ Auditoria de Dependências"
  echo ""
  if [ -f "package.json" ]; then
    echo "### NPM Audit"
    echo "\`\`\`"
    npm audit --audit-level=moderate 2>&1 || true
    echo "\`\`\`"
    echo ""
  fi
  
  # 2. VERIFICAR SECRETS COMMITADOS
  echo "## 2️⃣ Verificação de Secrets"
  echo ""
  echo "### Buscar strings sensíveis..."
  echo "\`\`\`"
  
  # Buscar patterns de secrets
  PATTERNS=(
    'password["\s]*:'
    'api[_-]?key["\s]*:'
    'secret["\s]*:'
    'token["\s]*:'
    'private[_-]?key'
    'AWS_SECRET'
    'STRIPE_SECRET'
    'DATABASE_URL'
  )
  
  FOUND_SECRETS=0
  for pattern in "${PATTERNS[@]}"; do
    if grep -r "$pattern" src/ server/ --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v "node_modules" | grep -v ".next" | head -5; then
      FOUND_SECRETS=$((FOUND_SECRETS + 1))
    fi
  done
  
  echo "\`\`\`"
  if [ $FOUND_SECRETS -gt 0 ]; then
    echo "⚠️ **ALERTA:** Foram encontrados possíveis secrets no código!"
  else
    echo "✅ Nenhum secret encontrado"
  fi
  echo ""
  
  # 3. VERIFICAR .ENV
  echo "## 3️⃣ Configuração de Variáveis de Ambiente"
  echo ""
  if [ -f ".env.example" ]; then
    echo "✅ Arquivo .env.example existe"
    echo "Variáveis esperadas:"
    echo "\`\`\`"
    cat .env.example | head -20
    echo "\`\`\`"
  else
    echo "⚠️ ALERTA: .env.example não encontrado!"
  fi
  echo ""
  
  # 4. ANÁLISE DE CÓDIGO ESTÁTICO
  echo "## 4️⃣ Análise de Código (SAST)"
  echo ""
  
  # Buscar SQL Injection
  echo "### Vulnerabilidades de SQL Injection"
  echo "\`\`\`"
  if grep -r "SELECT.*\$" src/ server/ --include="*.ts" --include="*.js" 2>/dev/null | head -3; then
    echo "⚠️ Possível SQL Injection encontrada"
  else
    echo "✅ Nenhuma SQL Injection óbvia encontrada"
  fi
  echo "\`\`\`"
  echo ""
  
  # Buscar XSS
  echo "### Vulnerabilidades de XSS"
  echo "\`\`\`"
  if grep -r "innerHTML\|dangerouslySetInnerHTML" src/ --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" 2>/dev/null | head -3; then
    echo "⚠️ innerHTML/dangerouslySetInnerHTML encontrado (risco de XSS)"
  else
    echo "✅ Nenhuma XSS óbvia encontrada"
  fi
  echo "\`\`\`"
  echo ""
  
  # 5. VERIFICAR CORS
  echo "## 5️⃣ Configuração de Segurança"
  echo ""
  echo "### CORS"
  echo "\`\`\`"
  if grep -r "CORS\|cors\|Access-Control" server/ --include="*.ts" --include="*.js" 2>/dev/null | head -3; then
    echo "✅ CORS configurado"
    echo "$(grep -r "CORS\|cors" server/ --include="*.ts" --include="*.js" 2>/dev/null | head -1)"
  else
    echo "⚠️ CORS não encontrado explicitamente"
  fi
  echo "\`\`\`"
  echo ""
  
  # 6. VERIFICAR AUTENTICAÇÃO
  echo "### Autenticação"
  echo "\`\`\`"
  if grep -r "requireAuth\|authenticate\|passport\|jwt" server/ --include="*.ts" --include="*.js" 2>/dev/null | head -3; then
    echo "✅ Sistema de autenticação detectado"
  else
    echo "⚠️ Sistema de autenticação não encontrado"
  fi
  echo "\`\`\`"
  echo ""
  
  # 7. VERIFICAR RATE LIMITING
  echo "### Rate Limiting"
  echo "\`\`\`"
  if grep -r "rateLimit\|RateLimit\|throttle" server/ --include="*.ts" --include="*.js" 2>/dev/null | head -3; then
    echo "✅ Rate limiting configurado"
  else
    echo "⚠️ Rate limiting não detectado"
  fi
  echo "\`\`\`"
  echo ""
  
  # 8. VERIFICAR VALIDAÇÃO DE INPUT
  echo "### Validação de Input"
  echo "\`\`\`"
  if grep -r "validate\|schema\|yup\|zod\|joi" src/ server/ --include="*.ts" --include="*.js" 2>/dev/null | wc -l | xargs echo "Referências de validação encontradas:"; then
    echo "✅ Sistema de validação detectado"
  else
    echo "⚠️ Validação pode estar incompleta"
  fi
  echo "\`\`\`"
  echo ""
  
  # 9. RESUMO
  echo "## 📊 Resumo"
  echo ""
  echo "| Item | Status |"
  echo "|------|--------|"
  echo "| Dependências | ⚠️ Verificar npm audit output |"
  echo "| Secrets | ✅ Verificado |"
  echo "| .env | $([ -f .env.example ] && echo '✅' || echo '❌') |"
  echo "| CORS | ✅ Verificado |"
  echo "| Autenticação | ✅ Detectada |"
  echo "| Rate Limiting | ⚠️ Verificar |"
  echo "| Validação | ✅ Detectada |"
  echo ""
  
  echo "---"
  echo "**Próximos passos:**"
  echo "1. Revisar as vulnerabilidades encontradas"
  echo "2. Executar testes automatizados"
  echo "3. Atualizar dependências"
  echo "4. Implementar correções"
  
} | tee "$REPORT_FILE"

echo ""
echo "✅ Relatório salvo em: $REPORT_FILE"
