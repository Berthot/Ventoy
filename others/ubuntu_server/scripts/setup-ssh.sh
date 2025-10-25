#!/bin/bash
# setup-ssh.sh - Script para configurar SSH automaticamente no Ubuntu Server
# Uso: ./setup-ssh.sh [IP_DO_SERVIDOR] [USUARIO]

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

# Verificar se está sendo executado como root
if [ "$EUID" -eq 0 ]; then
    log_error "Não execute este script como root!"
    exit 1
fi

# Parâmetros
SERVER_IP=${1:-""}
USERNAME=${2:-""}

echo "=========================================="
echo "    Configuração SSH para Ubuntu Server"
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
    read -p "Digite o IP do servidor: " SERVER_IP
fi

if [ -z "$USERNAME" ]; then
    read -p "Digite o nome do usuário: " USERNAME
fi

log_info "Configurando SSH para $USERNAME@$SERVER_IP"

# Criar diretório .ssh se não existir
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Verificar se existem chaves no Ventoy
VENTOY_SSH_PATH="$VENTOY_PATH/others/ubuntu_server/ssh"
if [ -d "$VENTOY_SSH_PATH" ]; then
    log_info "Verificando chaves SSH no Ventoy..."
    
    # Copiar chave pública se existir
    if [ -f "$VENTOY_SSH_PATH/id_rsa.pub" ]; then
        cp "$VENTOY_SSH_PATH/id_rsa.pub" ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        log_success "Chave pública copiada do Ventoy"
    fi
    
    # Copiar chave privada se existir
    if [ -f "$VENTOY_SSH_PATH/id_rsa" ]; then
        cp "$VENTOY_SSH_PATH/id_rsa" ~/.ssh/
        chmod 600 ~/.ssh/id_rsa
        log_success "Chave privada copiada do Ventoy"
    fi
else
    log_warning "Pasta de chaves SSH não encontrada no Ventoy"
fi

# Configurar SSH client
log_info "Configurando SSH client..."

# Criar configuração SSH
cat > ~/.ssh/config << EOF
# Configuração SSH para CasaOS Server
Host casaos-server
    HostName $SERVER_IP
    User $USERNAME
    Port 22
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Configuração alternativa (sem alias)
Host $SERVER_IP
    User $USERNAME
    Port 22
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

chmod 600 ~/.ssh/config

log_success "Configuração SSH criada em ~/.ssh/config"

# Testar conexão
log_info "Testando conexão SSH..."
if ssh -o ConnectTimeout=10 -o BatchMode=yes casaos-server "echo 'Conexão SSH funcionando!'" 2>/dev/null; then
    log_success "✅ Conexão SSH estabelecida com sucesso!"
    log_info "Para conectar: ssh casaos-server"
else
    log_warning "⚠️  Não foi possível testar a conexão automaticamente"
    log_info "Verifique se:"
    log_info "  - O servidor está ligado e acessível"
    log_info "  - As chaves SSH estão corretas"
    log_info "  - O usuário tem permissões adequadas"
fi

echo ""
echo "=========================================="
echo "    Configuração SSH Concluída!"
echo "=========================================="
echo ""
echo "Comandos úteis:"
echo "  ssh casaos-server                    # Conectar ao servidor"
echo "  ssh $USERNAME@$SERVER_IP             # Conectar diretamente"
echo "  scp arquivo casaos-server:/path/    # Copiar arquivo"
echo ""
echo "⚠️  IMPORTANTE: Mantenha suas chaves privadas seguras!"
echo "   - Nunca compartilhe chaves privadas"
echo "   - Use senhas fortes nas chaves"
echo "   - Faça backup das chaves em local seguro"
