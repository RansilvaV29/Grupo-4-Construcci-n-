#!/bin/bash
# Script de verificación pre-publicación
# Ejecuta este script antes de hacer push a GitHub

set -e

echo "═══════════════════════════════════════════════════════════"
echo "  🔍 VERIFICACIÓN PRE-PUBLICACIÓN"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de errores
ERRORS=0
WARNINGS=0

# ============================================================================
# 1. VERIFICAR QUE .env NO ESTÉ EN STAGING
# ============================================================================
echo "📋 Verificando archivos .env..."
if git diff --cached --name-only | grep -q "^.env$"; then
    echo -e "${RED}❌ ERROR: .env está en staging!${NC}"
    echo "   Ejecuta: git reset .env"
    ERRORS=$((ERRORS + 1))
elif git ls-files | grep -q "^.env$"; then
    echo -e "${RED}❌ ERROR: .env está siendo trackeado por git!${NC}"
    echo "   Ejecuta: git rm --cached .env"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ .env no está siendo trackeado${NC}"
fi

# ============================================================================
# 2. VERIFICAR QUE .env.example EXISTA
# ============================================================================
echo ""
echo "📋 Verificando .env.example..."
if [ -f ".env.example" ]; then
    echo -e "${GREEN}✅ .env.example existe${NC}"
else
    echo -e "${RED}❌ ERROR: .env.example no existe!${NC}"
    ERRORS=$((ERRORS + 1))
fi

# ============================================================================
# 3. VERIFICAR QUE .gitignore EXISTA Y CONTENGA .env
# ============================================================================
echo ""
echo "📋 Verificando .gitignore..."
if [ -f ".gitignore" ]; then
    if grep -q "^\.env$" .gitignore; then
        echo -e "${GREEN}✅ .gitignore existe y contiene .env${NC}"
    else
        echo -e "${YELLOW}⚠️  WARNING: .gitignore no contiene .env${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}❌ ERROR: .gitignore no existe!${NC}"
    ERRORS=$((ERRORS + 1))
fi

# ============================================================================
# 4. VERIFICAR ARCHIVOS CON CREDENCIALES
# ============================================================================
echo ""
echo "📋 Buscando credenciales hardcodeadas..."
SENSITIVE_PATTERNS=(
    "password.*=.*['\"][^'\"]+['\"]"
    "secret.*=.*['\"][^'\"]+['\"]"
    "api[_-]?key.*=.*['\"][^'\"]+['\"]"
    "access[_-]?key.*=.*['\"][^'\"]+['\"]"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if git diff --cached | grep -iE "$pattern" | grep -v ".env.example" | grep -q .; then
        echo -e "${YELLOW}⚠️  WARNING: Posible credencial encontrada en staging${NC}"
        git diff --cached | grep -iE "$pattern" | head -n 3
        WARNINGS=$((WARNINGS + 1))
    fi
done

if [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ No se encontraron credenciales hardcodeadas${NC}"
fi

# ============================================================================
# 5. VERIFICAR ARCHIVOS ESPECÍFICOS DEL PROYECTO
# ============================================================================
echo ""
echo "📋 Verificando archivos del proyecto..."

# Para repositorio de deployment
if [ -f "docker-compose.remote.yml" ]; then
    echo ""
    echo "  🐳 Repositorio de Deployment detectado"
    
    # Verificar que docker-compose apunte a repos correctos
    if grep -q "Erickxse/dj_py_bck.git" docker-compose.remote.yml && \
       grep -q "Erickxse/nx_js_ft.git" docker-compose.remote.yml; then
        echo -e "${GREEN}  ✅ docker-compose.remote.yml apunta a repos correctos${NC}"
    else
        echo -e "${RED}  ❌ ERROR: docker-compose.remote.yml no apunta a repos correctos!${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Verificar documentación
    DOCS=("README.md" "QUICK_START.md" ".env.example")
    for doc in "${DOCS[@]}"; do
        if [ -f "$doc" ]; then
            echo -e "${GREEN}  ✅ $doc existe${NC}"
        else
            echo -e "${YELLOW}  ⚠️  WARNING: $doc no existe${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
fi

# Para repositorio de backend
if [ -f "manage.py" ]; then
    echo ""
    echo "  🐍 Repositorio Backend (Django) detectado"
    
    if [ -f "Dockerfile" ]; then
        echo -e "${GREEN}  ✅ Dockerfile existe${NC}"
    else
        echo -e "${RED}  ❌ ERROR: Dockerfile no existe!${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if [ -f "requirements.txt" ]; then
        echo -e "${GREEN}  ✅ requirements.txt existe${NC}"
    else
        echo -e "${RED}  ❌ ERROR: requirements.txt no existe!${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Para repositorio de frontend
if [ -f "next.config.mjs" ] || [ -f "next.config.js" ]; then
    echo ""
    echo "  ⚛️  Repositorio Frontend (Next.js) detectado"
    
    if [ -f "Dockerfile.remote" ]; then
        echo -e "${GREEN}  ✅ Dockerfile.remote existe${NC}"
    else
        echo -e "${YELLOW}  ⚠️  WARNING: Dockerfile.remote no existe${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Verificar rewrite en next.config
    if [ -f "next.config.mjs" ]; then
        if grep -q "rewrites" next.config.mjs && grep -q "/bapi" next.config.mjs; then
            echo -e "${GREEN}  ✅ Rewrite /bapi configurado en next.config.mjs${NC}"
        else
            echo -e "${YELLOW}  ⚠️  WARNING: Rewrite /bapi no encontrado en next.config.mjs${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi

# ============================================================================
# 6. VERIFICAR GIT STATUS
# ============================================================================
echo ""
echo "📋 Verificando estado de Git..."

# Verificar que hay cambios staged
if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️  WARNING: No hay cambios en staging (git add)${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Hay cambios en staging listos para commit${NC}"
    echo ""
    echo "   Archivos a commitear:"
    git diff --cached --name-only | sed 's/^/   - /'
fi

# Verificar branch
CURRENT_BRANCH=$(git branch --show-current)
echo ""
echo "   Branch actual: $CURRENT_BRANCH"
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo -e "${GREEN}✅ Estás en branch principal${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING: No estás en main/master${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# ============================================================================
# RESUMEN FINAL
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  📊 RESUMEN"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ ¡Todo correcto! Puedes hacer push con seguridad.${NC}"
    echo ""
    echo "Ejecuta:"
    echo "  git commit -m 'tu mensaje'"
    echo "  git push origin $CURRENT_BRANCH"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS advertencia(s) encontrada(s)${NC}"
    echo ""
    echo "Puedes continuar, pero revisa las advertencias."
    echo ""
    echo "Ejecuta:"
    echo "  git commit -m 'tu mensaje'"
    echo "  git push origin $CURRENT_BRANCH"
    exit 0
else
    echo -e "${RED}❌ $ERRORS error(es) encontrado(s)${NC}"
    echo -e "${YELLOW}⚠️  $WARNINGS advertencia(s) encontrada(s)${NC}"
    echo ""
    echo "⛔ NO HAGAS PUSH HASTA CORREGIR LOS ERRORES"
    echo ""
    echo "Comandos útiles:"
    echo "  git status           # Ver estado"
    echo "  git reset .env       # Quitar .env del staging"
    echo "  git rm --cached .env # Dejar de trackear .env"
    exit 1
fi
