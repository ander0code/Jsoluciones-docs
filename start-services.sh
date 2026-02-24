#!/bin/bash
# ============================================
# JSOLUCIONES - Iniciar servicios requeridos
# PostgreSQL + Redis (Valkey)
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
if systemctl is-active --quiet postgresql; then
    echo -e "  PostgreSQL  ${GREEN}ya esta activo${NC}"
else
    echo -e "  PostgreSQL  ${YELLOW}iniciando...${NC}"
    sudo systemctl start postgresql
    if systemctl is-active --quiet postgresql; then
        echo -e "  PostgreSQL  ${GREEN}listo${NC}"
    else
        echo -e "  PostgreSQL  ${RED}fallo al iniciar${NC}"
    fi
fi

# --- Redis (Valkey) ---
if systemctl is-active --quiet valkey; then
    echo -e "  Redis       ${GREEN}ya esta activo${NC}"
else
    echo -e "  Redis       ${YELLOW}iniciando...${NC}"
    sudo systemctl start valkey
    if systemctl is-active --quiet valkey; then
        echo -e "  Redis       ${GREEN}listo${NC}"
    else
        echo -e "  Redis       ${RED}fallo al iniciar${NC}"
    fi
fi

echo ""
echo "=========================================="
echo "  Estado final:"
echo -e "  PostgreSQL  $(systemctl is-active postgresql)"
echo -e "  Redis       $(systemctl is-active valkey)"
echo "=========================================="
echo ""
