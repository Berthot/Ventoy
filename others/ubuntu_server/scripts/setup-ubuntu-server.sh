#!/bin/bash
# setup-ubuntu-server.sh - Script interativo para configurar Ubuntu Server
# Uso: ./setup-ubuntu-server.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações padrão
DEFAULT_USER="matheus.bertho"
DEFAULT_SSH_PORT="22"
VENTOY_PATH="/media/bertho/Ventoy"
SSH_PATH="$VENTOY_PATH/others/ubuntu_server/ssh"
BACKUP_PATH="$VENTOY_PATH/others/ubuntu_server/ssh-backup"

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Função para verificar se o Ventoy está montado
check_ventoy() {
    if [ ! -d "$VENTOY_PATH" ]; then
        log_error "Pasta do Ventoy não encontrada: $VENTOY_PATH"
        log_info "Certifique-se de que o pendrive está montado corretamente"
        exit 1
    fi
    log_success "Ventoy encontrado em: $VENTOY_PATH"
}

# Função para detectar IP automaticamente
detect_ip() {
    log_info "Detectando IP automaticamente..."
    local detected_ip=$(hostname -I | awk '{print $1}')
    
    if [[ -n "$detected_ip" && "$detected_ip" != "127.0.0.1" ]]; then
        log_success "IP detectado: $detected_ip"
        echo ""
        read -p "Usar este IP? (Y/n): " use_detected
        if [[ "$use_detected" =~ ^[Nn]$ ]]; then
            read -p "Digite o IP do servidor: " detected_ip
        fi
        echo "$detected_ip"
    else
        log_warning "Não foi possível detectar IP automaticamente"
        read -p "Digite o IP do servidor: " detected_ip
        echo "$detected_ip"
    fi
}

# Função para obter usuário
get_username() {
    read -p "Usuário (padrão: $DEFAULT_USER): " username
    echo "${username:-$DEFAULT_USER}"
}

# Função para mostrar menu
show_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Configuração Ubuntu Server${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo ""
    echo "1) Gerar chaves SSH"
    echo "2) Configurar SSH no servidor"
    echo "3) Conectar ao servidor"
    echo "4) Fazer backup das chaves"
    echo "5) Verificar status da conexão"
    echo "0) Sair"
    echo ""
    echo -e "${CYAN}========================================${NC}"
}

# Função para gerar chaves SSH
generate_ssh_keys() {
    log_step "Gerando chaves SSH..."
    
    # Criar diretório SSH se não existir
    mkdir -p "$SSH_PATH"
    
    # Verificar se chave já existe
    if [ -f "$SSH_PATH/id_rsa" ]; then
        log_warning "Chave SSH já existe: $SSH_PATH/id_rsa"
        read -p "Deseja sobrescrever? (y/N): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            log_info "Operação cancelada."
            return 0
        fi
    fi
    
    log_info "Gerando chave SSH RSA 4096 bits..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_PATH/id_rsa" -N "" -C "ubuntu-server-$(date +%Y-%m-%d)"
    
    # Definir permissões corretas
    chmod 600 "$SSH_PATH/id_rsa"
    chmod 644 "$SSH_PATH/id_rsa.pub"
    
    log_success "Chave SSH gerada com sucesso!"
    
    # Exibir informações da chave
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Informações da Chave Gerada${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "Chave privada: $SSH_PATH/id_rsa"
    echo "Chave pública: $SSH_PATH/id_rsa.pub"
    echo ""
    
    # Exibir fingerprint
    log_info "Fingerprint da chave:"
    ssh-keygen -lf "$SSH_PATH/id_rsa.pub"
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Chave Pública (copie para o servidor)${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    cat "$SSH_PATH/id_rsa.pub"
    echo ""
    
    # Oferecer adicionar senha à chave
    read -p "Deseja adicionar uma senha à chave privada? (y/N): " add_passphrase
    if [[ "$add_passphrase" =~ ^[Yy]$ ]]; then
        log_info "Adicionando senha à chave privada..."
        ssh-keygen -p -f "$SSH_PATH/id_rsa"
        log_success "Senha adicionada à chave privada!"
    fi
    
    log_success "Chaves SSH geradas e configuradas!"
}

# Função para configurar SSH
configure_ssh() {
    log_step "Configurando SSH..."
    
    # Detectar IP
    local server_ip=$(detect_ip)
    local username=$(get_username)
    
    log_info "Configurando SSH para $username@$server_ip"
    
    # Criar diretório .ssh se não existir
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Copiar chaves do Ventoy para ~/.ssh
    if [ -f "$SSH_PATH/id_rsa" ]; then
        cp "$SSH_PATH/id_rsa" ~/.ssh/
        chmod 600 ~/.ssh/id_rsa
        log_success "Chave privada copiada para ~/.ssh/"
    else
        log_error "Chave privada não encontrada em: $SSH_PATH/id_rsa"
        log_info "Execute a opção 1 primeiro para gerar as chaves"
        return 1
    fi
    
    if [ -f "$SSH_PATH/id_rsa.pub" ]; then
        cp "$SSH_PATH/id_rsa.pub" ~/.ssh/
        chmod 644 ~/.ssh/id_rsa.pub
        log_success "Chave pública copiada para ~/.ssh/"
    fi
    
    # Criar configuração SSH
    log_info "Criando configuração SSH..."
    cat > ~/.ssh/config << EOF
# Configuração SSH para Ubuntu Server
Host ubuntu-server
    HostName $server_ip
    User $username
    Port $DEFAULT_SSH_PORT
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Configuração alternativa (sem alias)
Host $server_ip
    User $username
    Port $DEFAULT_SSH_PORT
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
    
    chmod 600 ~/.ssh/config
    log_success "Configuração SSH criada em ~/.ssh/config"
    
    # Testar conexão
    log_info "Testando conexão SSH..."
    if ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu-server "echo 'Conexão SSH funcionando!'" 2>/dev/null; then
        log_success "✅ Conexão SSH estabelecida com sucesso!"
        log_info "Para conectar: ssh ubuntu-server"
    else
        log_warning "⚠️  Não foi possível testar a conexão automaticamente"
        log_info "Verifique se:"
        log_info "  - O servidor está ligado e acessível"
        log_info "  - As chaves SSH estão corretas"
        log_info "  - O usuário tem permissões adequadas"
        log_info "  - A chave pública foi adicionada ao servidor"
    fi
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Configuração SSH Concluída!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "Comandos úteis:"
    echo "  ssh ubuntu-server                    # Conectar ao servidor"
    echo "  ssh $username@$server_ip             # Conectar diretamente"
    echo "  scp arquivo ubuntu-server:/path/    # Copiar arquivo"
    echo ""
}

# Função para conectar ao servidor
connect_server() {
    log_step "Conectando ao servidor..."
    
    # Verificar se configuração existe
    if [ -f ~/.ssh/config ] && grep -q "Host ubuntu-server" ~/.ssh/config; then
        log_info "Usando configuração existente..."
        ssh ubuntu-server
    else
        log_warning "Configuração SSH não encontrada"
        log_info "Execute a opção 2 primeiro para configurar SSH"
        
        # Oferecer conexão manual
        read -p "Deseja conectar manualmente? (y/N): " manual_connect
        if [[ "$manual_connect" =~ ^[Yy]$ ]]; then
            local server_ip=$(detect_ip)
            local username=$(get_username)
            log_info "Conectando a $username@$server_ip..."
            ssh -o StrictHostKeyChecking=no "$username@$server_ip"
        fi
    fi
}

# Função para fazer backup das chaves
backup_keys() {
    log_step "Fazendo backup das chaves SSH..."
    
    # Criar diretório de backup
    local backup_dir="$BACKUP_PATH/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    log_info "Destino do backup: $backup_dir"
    
    # Verificar se existe diretório .ssh
    if [ ! -d "$HOME/.ssh" ]; then
        log_warning "Diretório ~/.ssh não encontrado"
        log_info "Nenhuma chave SSH para fazer backup"
        return 0
    fi
    
    log_info "Fazendo backup das chaves SSH de $HOME/.ssh"
    
    # Copiar todo o diretório .ssh
    cp -r "$HOME/.ssh" "$backup_dir/"
    
    # Definir permissões corretas
    chmod 700 "$backup_dir/.ssh"
    find "$backup_dir/.ssh" -name "id_*" -type f -exec chmod 600 {} \;
    find "$backup_dir/.ssh" -name "*.pub" -type f -exec chmod 644 {} \;
    find "$backup_dir/.ssh" -name "config" -type f -exec chmod 600 {} \;
    find "$backup_dir/.ssh" -name "known_hosts" -type f -exec chmod 644 {} \;
    
    log_success "Backup das chaves SSH concluído!"
    
    # Listar arquivos copiados
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Arquivos Copiados${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    ls -la "$backup_dir/.ssh/"
    echo ""
    
    # Verificar integridade do backup
    log_info "Verificando integridade do backup..."
    local original_count=$(find "$HOME/.ssh" -type f | wc -l)
    local backup_count=$(find "$backup_dir/.ssh" -type f | wc -l)
    
    if [ "$original_count" -eq "$backup_count" ]; then
        log_success "✅ Integridade do backup verificada ($backup_count arquivos)"
    else
        log_warning "⚠️  Diferença no número de arquivos:"
        log_warning "   Original: $original_count arquivos"
        log_warning "   Backup: $backup_count arquivos"
    fi
    
    # Mostrar tamanho do backup
    local backup_size=$(du -sh "$backup_dir" | cut -f1)
    log_info "Tamanho do backup: $backup_size"
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Backup Concluído!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "Localização: $backup_dir"
    echo "Tamanho: $backup_size"
    echo "Arquivos: $backup_count"
    echo ""
}

# Função para verificar status da conexão
check_status() {
    log_step "Verificando status da conexão..."
    
    # Mostrar configuração atual
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Configuração Atual${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    if [ -f ~/.ssh/config ]; then
        log_info "Configuração SSH encontrada:"
        grep -A 5 "Host ubuntu-server" ~/.ssh/config | sed 's/^/  /'
    else
        log_warning "Configuração SSH não encontrada"
    fi
    
    echo ""
    
    # Extrair IP e usuário da configuração
    local server_ip=""
    local username=""
    
    if [ -f ~/.ssh/config ]; then
        server_ip=$(grep -A 5 "Host ubuntu-server" ~/.ssh/config | grep "HostName" | awk '{print $2}')
        username=$(grep -A 5 "Host ubuntu-server" ~/.ssh/config | grep "User" | awk '{print $2}')
    fi
    
    if [ -z "$server_ip" ]; then
        log_warning "IP do servidor não configurado"
        return 1
    fi
    
    # Testar ping ao servidor
    log_info "Testando ping ao servidor ($server_ip)..."
    if ping -c 3 -W 3 "$server_ip" >/dev/null 2>&1; then
        log_success "Servidor acessível via ping"
    else
        log_warning "Servidor não responde ao ping"
    fi
    
    # Verificar porta SSH
    log_info "Verificando porta SSH (22)..."
    if timeout 5 bash -c "</dev/tcp/$server_ip/22" 2>/dev/null; then
        log_success "Porta SSH (22) está aberta"
    else
        log_error "Porta SSH (22) não está acessível"
        return 1
    fi
    
    # Testar autenticação
    if [ -n "$username" ]; then
        log_info "Testando autenticação SSH..."
        if ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu-server "echo 'Autenticação SSH funcionando!'" 2>/dev/null; then
            log_success "✅ Autenticação SSH funcionando!"
        else
            log_warning "⚠️  Autenticação SSH falhou"
            log_info "Verifique se:"
            log_info "  - A chave pública está no servidor"
            log_info "  - As permissões da chave estão corretas"
            log_info "  - O usuário tem acesso ao servidor"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Status da Conexão${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "Servidor: $server_ip"
    echo "Usuário: $username"
    echo "Chave: ~/.ssh/id_rsa"
    echo "Alias: ubuntu-server"
    echo ""
}

# Função principal
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Configuração Ubuntu Server${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "Script interativo para configurar SSH no Ubuntu Server"
    echo "Usuário padrão: $DEFAULT_USER"
    echo "Path Ventoy: $VENTOY_PATH"
    echo ""
    
    # Verificar Ventoy
    check_ventoy
    
    # Loop principal do menu
    while true; do
        show_menu
        read -p "Digite sua escolha: " choice
        
        case $choice in
            1)
                generate_ssh_keys
                ;;
            2)
                configure_ssh
                ;;
            3)
                connect_server
                ;;
            4)
                backup_keys
                ;;
            5)
                check_status
                ;;
            0)
                log_info "Saindo..."
                exit 0
                ;;
            *)
                log_error "Opção inválida. Tente novamente."
                ;;
        esac
        
        echo ""
        read -p "Pressione Enter para continuar..."
    done
}

# Executar função principal
main "$@"
