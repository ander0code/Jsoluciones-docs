#!/bin/bash
# ============================================
# JSOLUCIONES - Iniciar servicios requeridos
# PostgreSQL + Redis
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=========================================="
echo "  JSOLUCIONES - Iniciando servicios"
echo "=========================================="
echo ""

# --- PostgreSQL ---
if brew services list | grep -q "postgresql@17.*started"; then
    echo -e "  PostgreSQL  ${GREEN}ya esta activo${NC}"
else
    echo -e "  PostgreSQL  ${YELLOW}iniciando...${NC}"
    brew services start postgresql@17
    sleep 2
    if brew services list | grep -q "postgresql@17.*started"; then
        echo -e "  PostgreSQL  ${GREEN}listo${NC}"
    else
        echo -e "  PostgreSQL  ${RED}fallo al iniciar${NC}"
    fi
fi

# --- Redis ---
if brew services list | grep -q "redis.*started"; then
    echo -e "  Redis       ${GREEN}ya esta activo${NC}"
else
    echo -e "  Redis       ${YELLOW}iniciando...${NC}"
    brew services start redis
    sleep 2
    if brew services list | grep -q "redis.*started"; then
        echo -e "  Redis       ${GREEN}listo${NC}"
    else
        echo -e "  Redis       ${RED}fallo al iniciar${NC}"
    fi
fi

echo ""
echo "=========================================="
echo "  Estado final:"
echo -e "  PostgreSQL  $(brew services list | grep postgresql@17 | awk '{print $2}')"
echo -e "  Redis       $(brew services list | grep -E '^redis\s' | awk '{print $2}')"
echo "=========================================="
echo ""
