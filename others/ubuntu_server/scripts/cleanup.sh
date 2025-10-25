#!/bin/bash

# Script para limpar ambiente de testes Ubuntu Server
# Parte do sistema Ubuntu Server Docker Test Environment

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
CONTAINER_NAME="ubuntu-server-test"

# Função para logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[${timestamp}] INFO: ${message}${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[${timestamp}] SUCCESS: ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[${timestamp}] ERROR: ${message}${NC}"
            ;;
        "STEP")
            echo -e "${YELLOW}[${timestamp}] STEP: ${message}${NC}"
            ;;
    esac
}

# Função para confirmar limpeza
confirm_cleanup() {
    echo ""
    log "WARNING" "Esta operação irá:"
    echo "  - Parar o container '$CONTAINER_NAME'"
    echo "  - Remover o container '$CONTAINER_NAME'"
    echo "  - Limpar todas as configurações de teste"
    echo ""
    
    read -p "Tem certeza que deseja continuar? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Operação cancelada pelo usuário"
        exit 0
    fi
}

# Função para parar container
stop_container() {
    log "STEP" "Parando container..."
    
    if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "INFO" "Parando container '$CONTAINER_NAME'..."
        docker stop "$CONTAINER_NAME"
        log "SUCCESS" "Container parado com sucesso"
    else
        log "INFO" "Container '$CONTAINER_NAME' não está rodando"
    fi
}

# Função para remover container
remove_container() {
    log "STEP" "Removendo container..."
    
    if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "INFO" "Removendo container '$CONTAINER_NAME'..."
        docker rm "$CONTAINER_NAME"
        log "SUCCESS" "Container removido com sucesso"
    else
        log "INFO" "Container '$CONTAINER_NAME' não existe"
    fi
}

# Função para limpar chaves SSH de teste
cleanup_ssh_keys() {
    log "STEP" "Limpando chaves SSH de teste..."
    
    # Verificar se chaves de teste existem
    local test_key_exists=false
    
    if [[ -f ~/.ssh/id_rsa_test ]]; then
        test_key_exists=true
        log "INFO" "Removendo chave SSH de teste..."
        rm -f ~/.ssh/id_rsa_test
        rm -f ~/.ssh/id_rsa_test.pub
        log "SUCCESS" "Chave SSH de teste removida"
    fi
    
    # Verificar se há configuração SSH de teste
    if [[ -f ~/.ssh/config ]]; then
        if grep -q "ubuntu-server-test" ~/.ssh/config; then
            log "INFO" "Removendo configuração SSH de teste..."
            # Criar backup da configuração
            cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)
            
            # Remover linhas relacionadas ao teste
            sed -i '/# Ubuntu Server Test/,/^$/d' ~/.ssh/config
            log "SUCCESS" "Configuração SSH de teste removida"
        fi
    fi
    
    if [[ "$test_key_exists" == "false" ]]; then
        log "INFO" "Nenhuma chave SSH de teste encontrada"
    fi
}

# Função para limpar imagens Docker não utilizadas
cleanup_docker_images() {
    log "STEP" "Limpando imagens Docker não utilizadas..."
    
    # Verificar se há imagens órfãs
    local dangling_images=$(docker images -f "dangling=true" -q)
    if [[ -n "$dangling_images" ]]; then
        log "INFO" "Removendo imagens Docker órfãs..."
        docker rmi $dangling_images 2>/dev/null || true
        log "SUCCESS" "Imagens órfãs removidas"
    else
        log "INFO" "Nenhuma imagem órfã encontrada"
    fi
    
    # Verificar se há volumes não utilizados
    local dangling_volumes=$(docker volume ls -f "dangling=true" -q)
    if [[ -n "$dangling_volumes" ]]; then
        log "INFO" "Removendo volumes Docker não utilizados..."
        docker volume rm $dangling_volumes 2>/dev/null || true
        log "SUCCESS" "Volumes não utilizados removidos"
    else
        log "INFO" "Nenhum volume não utilizado encontrado"
    fi
}

# Função para limpar logs
cleanup_logs() {
    log "STEP" "Limpando logs..."
    
    # Limpar logs do Docker se existirem
    if [[ -f "/var/log/docker.log" ]]; then
        log "INFO" "Limpando logs do Docker..."
        sudo truncate -s 0 /var/log/docker.log 2>/dev/null || true
    fi
    
    log "SUCCESS" "Logs limpos"
}

# Função para verificar limpeza
verify_cleanup() {
    log "STEP" "Verificando limpeza..."
    
    # Verificar se container foi removido
    if ! docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "SUCCESS" "Container '$CONTAINER_NAME' foi removido com sucesso"
    else
        log "ERROR" "Container '$CONTAINER_NAME' ainda existe"
        return 1
    fi
    
    # Verificar se chaves SSH foram removidas
    if [[ ! -f ~/.ssh/id_rsa_test ]]; then
        log "SUCCESS" "Chaves SSH de teste foram removidas"
    else
        log "WARNING" "Chaves SSH de teste ainda existem"
    fi
    
    # Verificar se configuração SSH foi limpa
    if [[ ! -f ~/.ssh/config ]] || ! grep -q "ubuntu-server-test" ~/.ssh/config; then
        log "SUCCESS" "Configuração SSH de teste foi removida"
    else
        log "WARNING" "Configuração SSH de teste ainda existe"
    fi
    
    return 0
}

# Função para mostrar resumo da limpeza
show_cleanup_summary() {
    echo ""
    log "INFO" "=== RESUMO DA LIMPEZA ==="
    echo ""
    echo -e "${GREEN}Container:${NC} $CONTAINER_NAME - REMOVIDO"
    echo -e "${GREEN}Chaves SSH:${NC} Teste - REMOVIDAS"
    echo -e "${GREEN}Configuração SSH:${NC} Teste - REMOVIDA"
    echo -e "${GREEN}Imagens Docker:${NC} Órfãs - REMOVIDAS"
    echo -e "${GREEN}Volumes Docker:${NC} Não utilizados - REMOVIDOS"
    echo ""
    echo -e "${YELLOW}Ambiente limpo com sucesso!${NC}"
    echo ""
    log "INFO" "Para recriar o ambiente:"
    log "INFO" "  ./ubuntu_server.sh create"
    log "INFO" "  ./ubuntu_server.sh full"
    echo ""
}

# Função para limpeza forçada (sem confirmação)
force_cleanup() {
    log "STEP" "Executando limpeza forçada..."
    
    # Parar container se estiver rodando
    if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "INFO" "Parando container..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
    fi
    
    # Remover container se existir
    if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "INFO" "Removendo container..."
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    fi
    
    # Limpar chaves SSH de teste
    rm -f ~/.ssh/id_rsa_test ~/.ssh/id_rsa_test.pub 2>/dev/null || true
    
    # Limpar configuração SSH de teste
    if [[ -f ~/.ssh/config ]]; then
        sed -i '/# Ubuntu Server Test/,/^$/d' ~/.ssh/config 2>/dev/null || true
    fi
    
    # Limpar imagens e volumes órfãos
    docker rmi $(docker images -f "dangling=true" -q) 2>/dev/null || true
    docker volume rm $(docker volume ls -f "dangling=true" -q) 2>/dev/null || true
    
    log "SUCCESS" "Limpeza forçada concluída"
}

# Função principal
main() {
    # Verificar se argumento --force foi passado
    if [[ "$1" == "--force" ]]; then
        log "INFO" "Modo forçado ativado (sem confirmação)"
        force_cleanup
        show_cleanup_summary
        exit 0
    fi
    
    log "STEP" "Iniciando limpeza do ambiente de testes..."
    
    # Confirmar limpeza
    confirm_cleanup
    
    # Parar container
    stop_container
    
    # Remover container
    remove_container
    
    # Limpar chaves SSH
    cleanup_ssh_keys
    
    # Limpar imagens Docker
    cleanup_docker_images
    
    # Limpar logs
    cleanup_logs
    
    # Verificar limpeza
    if verify_cleanup; then
        show_cleanup_summary
        log "SUCCESS" "Ambiente limpo com sucesso!"
    else
        log "ERROR" "Alguns itens não foram limpos completamente"
        log "INFO" "Execute './ubuntu_server.sh cleanup --force' para limpeza forçada"
        exit 1
    fi
}

# Executar função principal
main "$@"
