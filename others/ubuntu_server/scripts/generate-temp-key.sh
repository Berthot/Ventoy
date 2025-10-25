#!/bin/bash
# generate-temp-key.sh - Script para gerar chaves SSH temporárias de forma segura
# Uso: ./generate-temp-key.sh [NOME_DA_CHAVE]

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
KEY_NAME=${1:-"temp_key_$(date +%Y%m%d_%H%M%S)"}

echo "=========================================="
echo "    Gerador de Chaves SSH Temporárias"
echo "=========================================="
echo ""

# Verificar se o Ventoy está montado
VENTOY_PATH="/media/bertho/Ventoy"
if [ ! -d "$VENTOY_PATH" ]; then
    log_error "Pasta do Ventoy não encontrada: $VENTOY_PATH"
    log_info "Certifique-se de que o pendrive está montado corretamente"
    exit 1
fi

# Criar diretório de chaves se não existir
VENTOY_SSH_PATH="$VENTOY_PATH/others/ubuntu_server/ssh"
mkdir -p "$VENTOY_SSH_PATH"

# Verificar se já existe uma chave com esse nome
if [ -f "$VENTOY_SSH_PATH/$KEY_NAME" ]; then
    log_warning "Já existe uma chave com o nome: $KEY_NAME"
    read -p "Deseja sobrescrever? (y/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        log_info "Operação cancelada."
        exit 0
    fi
fi

log_info "Gerando chave SSH temporária: $KEY_NAME"
log_info "Tipo: RSA 4096 bits"
log_info "Local: $VENTOY_SSH_PATH/$KEY_NAME"

# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -f "$VENTOY_SSH_PATH/$KEY_NAME" -N "" -C "temp_key_$(date +%Y-%m-%d)"

# Definir permissões corretas
chmod 600 "$VENTOY_SSH_PATH/$KEY_NAME"
chmod 644 "$VENTOY_SSH_PATH/$KEY_NAME.pub"

log_success "Chave SSH temporária gerada com sucesso!"

# Exibir informações da chave
echo ""
echo "=========================================="
echo "    Informações da Chave Gerada"
echo "=========================================="
echo ""
echo "Chave privada: $VENTOY_SSH_PATH/$KEY_NAME"
echo "Chave pública: $VENTOY_SSH_PATH/$KEY_NAME.pub"
echo ""

# Exibir fingerprint
log_info "Fingerprint da chave:"
ssh-keygen -lf "$VENTOY_SSH_PATH/$KEY_NAME.pub"

echo ""
echo "=========================================="
echo "    Chave Pública (copie para o servidor)"
echo "=========================================="
echo ""
cat "$VENTOY_SSH_PATH/$KEY_NAME.pub"
echo ""

# Instruções de uso
echo "=========================================="
echo "    Como Usar Esta Chave"
echo "=========================================="
echo ""
echo "1. Copie a chave pública acima para o servidor:"
echo "   ssh-copy-id -i $VENTOY_SSH_PATH/$KEY_NAME.pub usuario@servidor"
echo ""
echo "2. Ou adicione manualmente ao ~/.ssh/authorized_keys no servidor"
echo ""
echo "3. Conecte usando a chave privada:"
echo "   ssh -i $VENTOY_SSH_PATH/$KEY_NAME usuario@servidor"
echo ""
echo "4. Para usar com o script connect-casaos.sh:"
echo "   Renomeie a chave para 'id_rsa':"
echo "   cp $VENTOY_SSH_PATH/$KEY_NAME $VENTOY_SSH_PATH/id_rsa"
echo "   cp $VENTOY_SSH_PATH/$KEY_NAME.pub $VENTOY_SSH_PATH/id_rsa.pub"
echo ""

# Avisos de segurança
log_warning "⚠️  AVISOS DE SEGURANÇA:"
echo "  - Esta é uma chave temporária, use apenas para testes"
echo "  - Não use em produção sem proteção adicional"
echo "  - Mantenha a chave privada segura"
echo "  - Delete as chaves quando não precisar mais"
echo "  - Considere usar uma senha na chave para maior segurança"
echo ""

# Opção para adicionar senha à chave
read -p "Deseja adicionar uma senha à chave privada? (y/N): " ADD_PASSPHRASE
if [[ "$ADD_PASSPHRASE" =~ ^[Yy]$ ]]; then
    log_info "Adicionando senha à chave privada..."
    ssh-keygen -p -f "$VENTOY_SSH_PATH/$KEY_NAME"
    log_success "Senha adicionada à chave privada!"
fi

log_success "Processo concluído! Sua chave SSH temporária está pronta para uso."
