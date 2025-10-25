#!/bin/bash
# connect-casaos.sh - Script para conectar rapidamente ao servidor CasaOS
# Uso: ./connect-casaos.sh [IP] [USUARIO]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir mensagens
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parâmetros
SERVER_IP=${1:-""}
USERNAME=${2:-""}

echo "=========================================="
echo "    Conexão Rápida ao CasaOS Server"
echo "=========================================="
echo ""

# Verificar se o Ventoy está montado
VENTOY_PATH="/media/bertho/Ventoy"
if [ ! -d "$VENTOY_PATH" ]; then
    log_error "Pasta do Ventoy não encontrada: $VENTOY_PATH"
    log_info "Certifique-se de que o pendrive está montado corretamente"
    exit 1
fi

# Solicitar informações se não fornecidas
if [ -z "$SERVER_IP" ]; then
    read -p "Digite o IP do servidor CasaOS: " SERVER_IP
fi

if [ -z "$USERNAME" ]; then
    read -p "Digite o nome do usuário: " USERNAME
fi

# Verificar se existe chave privada no Ventoy
VENTOY_SSH_PATH="$VENTOY_PATH/others/ubuntu_server/ssh"
PRIVATE_KEY=""

if [ -f "$VENTOY_SSH_PATH/id_rsa" ]; then
    PRIVATE_KEY="$VENTOY_SSH_PATH/id_rsa"
    log_info "Usando chave privada do Ventoy: $PRIVATE_KEY"
elif [ -f "$HOME/.ssh/id_rsa" ]; then
    PRIVATE_KEY="$HOME/.ssh/id_rsa"
    log_info "Usando chave privada local: $PRIVATE_KEY"
else
    log_warning "Nenhuma chave privada encontrada!"
    log_info "Opções:"
    log_info "  1. Coloque sua chave privada em: $VENTOY_SSH_PATH/id_rsa"
    log_info "  2. Execute o script generate-temp-key.sh para gerar uma chave temporária"
    log_info "  3. Use autenticação por senha (menos seguro)"
    echo ""
    read -p "Deseja continuar com autenticação por senha? (y/N): " USE_PASSWORD
    if [[ ! "$USE_PASSWORD" =~ ^[Yy]$ ]]; then
        log_info "Operação cancelada."
        exit 0
    fi
fi

# Testar conectividade
log_info "Testando conectividade com $SERVER_IP..."
if ping -c 1 -W 3 "$SERVER_IP" >/dev/null 2>&1; then
    log_success "Servidor acessível via ping"
else
    log_warning "Servidor não responde ao ping, mas pode estar funcionando"
fi

# Verificar se a porta SSH está aberta
log_info "Verificando porta SSH (22)..."
if timeout 5 bash -c "</dev/tcp/$SERVER_IP/22" 2>/dev/null; then
    log_success "Porta SSH (22) está aberta"
else
    log_error "Porta SSH (22) não está acessível"
    log_info "Verifique se:"
    log_info "  - O servidor está ligado"
    log_info "  - O SSH está rodando (sudo systemctl status ssh)"
    log_info "  - O firewall permite conexões SSH"
    exit 1
fi

# Conectar ao servidor
log_info "Conectando ao servidor CasaOS..."
echo ""

if [ -n "$PRIVATE_KEY" ]; then
    # Conectar com chave privada
    log_info "Usando autenticação por chave privada"
    ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$USERNAME@$SERVER_IP"
else
    # Conectar com senha
    log_info "Usando autenticação por senha"
    ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER_IP"
fi

# Se chegou aqui, a conexão foi encerrada
log_info "Conexão SSH encerrada."
