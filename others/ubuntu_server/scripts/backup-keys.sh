#!/bin/bash
# backup-keys.sh - Script para fazer backup das chaves SSH existentes
# Uso: ./backup-keys.sh [DESTINO]

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
BACKUP_DEST=${1:-""}

echo "=========================================="
echo "    Backup de Chaves SSH"
echo "=========================================="
echo ""

# Verificar se o Ventoy está montado
VENTOY_PATH="/media/bertho/Ventoy"
if [ ! -d "$VENTOY_PATH" ]; then
    log_error "Pasta do Ventoy não encontrada: $VENTOY_PATH"
    log_info "Certifique-se de que o pendrive está montado corretamente"
    exit 1
fi

# Definir destino do backup
if [ -z "$BACKUP_DEST" ]; then
    BACKUP_DEST="$VENTOY_PATH/others/ubuntu_server/ssh-backup/$(date +%Y%m%d_%H%M%S)"
fi

log_info "Destino do backup: $BACKUP_DEST"

# Criar diretório de backup
mkdir -p "$BACKUP_DEST"

# Verificar se existe diretório .ssh
if [ ! -d "$HOME/.ssh" ]; then
    log_warning "Diretório ~/.ssh não encontrado"
    log_info "Nenhuma chave SSH para fazer backup"
    exit 0
fi

log_info "Fazendo backup das chaves SSH de $HOME/.ssh"

# Copiar todo o diretório .ssh
cp -r "$HOME/.ssh" "$BACKUP_DEST/"

# Definir permissões corretas
chmod 700 "$BACKUP_DEST/.ssh"
find "$BACKUP_DEST/.ssh" -name "id_*" -type f -exec chmod 600 {} \;
find "$BACKUP_DEST/.ssh" -name "*.pub" -type f -exec chmod 644 {} \;
find "$BACKUP_DEST/.ssh" -name "config" -type f -exec chmod 600 {} \;
find "$BACKUP_DEST/.ssh" -name "known_hosts" -type f -exec chmod 644 {} \;

log_success "Backup das chaves SSH concluído!"

# Listar arquivos copiados
echo ""
echo "=========================================="
echo "    Arquivos Copiados"
echo "=========================================="
echo ""
ls -la "$BACKUP_DEST/.ssh/"
echo ""

# Criar arquivo de informações do backup
cat > "$BACKUP_DEST/backup_info.txt" << EOF
Backup de Chaves SSH
===================

Data: $(date)
Usuário: $(whoami)
Sistema: $(uname -a)
Diretório original: $HOME/.ssh
Diretório backup: $BACKUP_DEST

Arquivos incluídos:
$(ls -la "$BACKUP_DEST/.ssh/" | grep -v "^total")

IMPORTANTE:
- Mantenha este backup em local seguro
- As chaves privadas são sensíveis
- Não compartilhe chaves privadas
- Use criptografia adicional se necessário
EOF

log_info "Informações do backup salvas em: $BACKUP_DEST/backup_info.txt"

# Verificar integridade do backup
log_info "Verificando integridade do backup..."

ORIGINAL_COUNT=$(find "$HOME/.ssh" -type f | wc -l)
BACKUP_COUNT=$(find "$BACKUP_DEST/.ssh" -type f | wc -l)

if [ "$ORIGINAL_COUNT" -eq "$BACKUP_COUNT" ]; then
    log_success "✅ Integridade do backup verificada ($BACKUP_COUNT arquivos)"
else
    log_warning "⚠️  Diferença no número de arquivos:"
    log_warning "   Original: $ORIGINAL_COUNT arquivos"
    log_warning "   Backup: $BACKUP_COUNT arquivos"
fi

# Mostrar tamanho do backup
BACKUP_SIZE=$(du -sh "$BACKUP_DEST" | cut -f1)
log_info "Tamanho do backup: $BACKUP_SIZE"

echo ""
echo "=========================================="
echo "    Backup Concluído!"
echo "=========================================="
echo ""
echo "Localização: $BACKUP_DEST"
echo "Tamanho: $BACKUP_SIZE"
echo "Arquivos: $BACKUP_COUNT"
echo ""
echo "Para restaurar as chaves:"
echo "  cp -r $BACKUP_DEST/.ssh/* ~/.ssh/"
echo "  chmod 700 ~/.ssh"
echo "  chmod 600 ~/.ssh/id_*"
echo "  chmod 644 ~/.ssh/*.pub"
echo ""
echo "⚠️  IMPORTANTE:"
echo "  - Mantenha este backup seguro"
echo "  - Não compartilhe chaves privadas"
echo "  - Considere criptografar o backup"
echo "  - Faça backups regulares"
