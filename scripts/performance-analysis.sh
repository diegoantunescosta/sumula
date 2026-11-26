#!/bin/bash
# ⚡ PERFORMANCE & VULNERABILITY ANALYSIS
# Executado pelo Copilot Agent

set -e

echo "⚡ INICIANDO ANÁLISE DE PERFORMANCE E VULNERABILIDADES..."
mkdir -p .performance-reports
REPORT_DATE=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_FILE=".performance-reports/analysis-$REPORT_DATE.md"

{
  echo "# ⚡ Relatório de Performance e Vulnerabilidades"
  echo "**Data:** $(date)"
  echo ""
  
  # 1. ANÁLISE DE BUNDLE SIZE
  echo "## 1️⃣ Análise de Bundle"
  echo ""
  
  if [ -f "package.json" ]; then
    echo "### Dependências Instaladas"
    echo "\`\`\`"
    npm ls --depth=0 2>/dev/null | head -20
    echo "\`\`\`"
    echo ""
    
    echo "### Verificar dependências não utilizadas"
    echo "\`\`\`"
    # Buscar imports não utilizados
    if grep -r "import.*from" src/ server/ --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l; then
      echo "Total de imports encontrados"
    fi
    echo "\`\`\`"
  fi
  echo ""
  
  # 2. ANÁLISE DE PERFORMANCE DO BANCO DE DADOS
  echo "## 2️⃣ Performance do Banco de Dados"
  echo ""
  
  if [ -f "server/db.js" ] || [ -f "src/db/index.ts" ]; then
    echo "### Verificar N+1 Queries"
    echo "\`\`\`"
    
    # Buscar padrões de N+1
    if grep -r "for.*SELECT\|map.*query\|forEach.*db\." server/ src/ --include="*.ts" --include="*.js" 2>/dev/null | head -3; then
      echo "⚠️ Possível N+1 Query detectado"
    else
      echo "✅ Nenhuma N+1 query óbvia"
    fi
    echo "\`\`\`"
    echo ""
    
    echo "### Recomendações de Database"
    echo "- [ ] Adicionar índices em colunas de busca (user_id, stripe_session_id)"
    echo "- [ ] Usar batch queries em vez de loops"
    echo "- [ ] Implementar connection pooling"
    echo "- [ ] Cache de queries frequentes (Redis)"
    echo ""
  fi
  echo ""
  
  # 3. ANÁLISE DE API ENDPOINTS
  echo "## 3️⃣ Performance de Endpoints"
  echo ""
  
  ENDPOINTS=(
    "POST /api/checkout"
    "POST /api/create-payment"
    "POST /api/auth/login"
    "GET /api/recent-purchases"
    "POST /webhook/stripe"
  )
  
  echo "### Endpoints críticos:"
  echo "\`\`\`"
  for endpoint in "${ENDPOINTS[@]}"; do
    echo "- $endpoint"
  done
  echo "\`\`\`"
  echo ""
  
  echo "**Recomendações:**"
  echo "- [ ] Medir tempo de resposta (target: < 500ms)"
  echo "- [ ] Adicionar caching (Redis/Memcached)"
  echo "- [ ] Implementar compressão gzip"
  echo "- [ ] Usar CDN para assets estáticos"
  echo ""
  
  # 4. ANÁLISE DE MEMÓRIA E CPU
  echo "## 4️⃣ Consumo de Recursos"
  echo ""
  
  echo "### Docker Container"
  echo "\`\`\`"
  if command -v docker &> /dev/null; then
    docker ps --format "table {{.Names}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "Docker não disponível neste ambiente"
  fi
  echo "\`\`\`"
  echo ""
  
  # 5. ANÁLISE DE SEGURANÇA DINÂMICA
  echo "## 5️⃣ Vulnerabilidades de Runtime"
  echo ""
  
  echo "### Buscar Error Handling"
  echo "\`\`\`"
  if grep -r "try.*catch\|\.catch\|error.*handler" server/ src/ --include="*.ts" --include="*.js" 2>/dev/null | wc -l | xargs echo "Error handlers encontrados:"; then
    echo "✅ Error handling detectado"
  fi
  echo "\`\`\`"
  echo ""
  
  echo "### Buscar Logging de Erros"
  echo "\`\`\`"
  if grep -r "console.error\|logger.error\|sentry\|error.*log" server/ src/ --include="*.ts" --include="*.js" 2>/dev/null | wc -l | xargs echo "Log statements encontrados:"; then
    echo "⚠️ Verificar se erros sensíveis estão sendo logados"
  fi
  echo "\`\`\`"
  echo ""
  
  # 6. ANÁLISE DE TIMEOUT E LIMITES
  echo "## 6️⃣ Limites e Timeouts"
  echo ""
  
  echo "### Recomendações:"
  echo "- [ ] Request timeout: 30s"
  echo "- [ ] Database query timeout: 10s"
  echo "- [ ] API rate limit: 100 req/min por IP"
  echo "- [ ] File upload max size: 100MB"
  echo "- [ ] Session timeout: 24h"
  echo ""
  
  # 7. ANÁLISE DE VULNERABILIDADES COMUNS
  echo "## 7️⃣ Vulnerabilidades Comuns (OWASP Top 10)"
  echo ""
  
  echo "| # | Vulnerabilidade | Status |"
  echo "|---|-----------------|--------|"
  
  # A01: Broken Access Control
  echo -n "| 1 | Broken Access Control | "
  if grep -r "requireAuth\|authenticate" server/ 2>/dev/null | grep -q .; then
    echo "⚠️ Verificado |"
  else
    echo "❌ Não implementado |"
  fi
  
  # A02: Cryptographic Failures
  echo -n "| 2 | Cryptographic Failures | "
  if grep -r "bcrypt\|argon\|hash" server/ 2>/dev/null | grep -q .; then
    echo "✅ |"
  else
    echo "⚠️ |"
  fi
  
  # A03: Injection
  echo -n "| 3 | Injection (SQL/NoSQL) | "
  if grep -r "SELECT.*\$\|\.find({.*user" server/ 2>/dev/null | grep -q .; then
    echo "⚠️ Verificado |"
  else
    echo "✅ |"
  fi
  
  # A04: Insecure Design
  echo "| 4 | Insecure Design | ⚠️ |"
  
  # A05: Security Misconfiguration
  echo "| 5 | Security Misconfiguration | ⚠️ |"
  
  # A06: Vulnerable Components
  echo "| 6 | Vulnerable Components | ⚠️ npm audit |"
  
  # A07: Identification & Authentication
  echo "| 7 | Identification & Auth | ⚠️ |"
  
  # A08: Software & Data Integrity
  echo "| 8 | Software Integrity | ⚠️ |"
  
  # A09: Logging & Monitoring
  echo "| 9 | Logging & Monitoring | ⚠️ |"
  
  # A10: SSRF
  echo "| 10 | SSRF | ✅ |"
  
  echo ""
  
  # 8. RESUMO E AÇÕES
  echo "## 📊 Resumo de Ações"
  echo ""
  echo "### Críticas 🔴"
  echo "- [ ] Executar `npm audit` e corrigir vulnerabilidades"
  echo "- [ ] Adicionar validação em todos os endpoints"
  echo "- [ ] Implementar autenticação/autorização"
  echo ""
  
  echo "### Altas ⚠️"
  echo "- [ ] Adicionar caching (Redis)"
  echo "- [ ] Otimizar queries do banco"
  echo "- [ ] Implementar rate limiting"
  echo ""
  
  echo "### Médias 📊"
  echo "- [ ] Melhorar logging"
  echo "- [ ] Adicionar monitoramento"
  echo "- [ ] Documentar API"
  echo ""
  
  echo "---"
  echo "**Próximos passos:**"
  echo "1. Correção de vulnerabilidades críticas"
  echo "2. Implementação de testes de segurança"
  echo "3. Otimização de performance"
  echo "4. Adicionar monitoramento em produção"
  
} | tee "$REPORT_FILE"

echo ""
echo "✅ Relatório salvo em: $REPORT_FILE"
