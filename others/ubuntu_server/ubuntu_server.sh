#!/bin/bash

# Ubuntu Server Docker Test Environment
# Orchestrator principal para gerenciar ambiente de testes

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
CONTAINER_NAME="ubuntu-server-test"
CONTAINER_IMAGE="ubuntu:22.04"
SSH_PORT="2222"
HTTP_PORT="8080"
HTTPS_PORT="8443"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

# Função para logging colorido
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
        "WARNING")
            echo -e "${YELLOW}[${timestamp}] WARNING: ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[${timestamp}] ERROR: ${message}${NC}"
            ;;
        "STEP")
            echo -e "${PURPLE}[${timestamp}] STEP: ${message}${NC}"
            ;;
        *)
            echo -e "${CYAN}[${timestamp}] ${message}${NC}"
            ;;
    esac
}

# Função para verificar dependências
check_dependencies() {
    log "STEP" "Verificando dependências..."
    
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker não está instalado. Instale o Docker primeiro."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker não está rodando. Inicie o serviço Docker."
        exit 1
    fi
    
    log "SUCCESS" "Dependências verificadas com sucesso"
}

# Função para mostrar menu interativo
show_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Ubuntu Server Docker Test Environment${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo ""
    echo "1) create    - Criar container Ubuntu Server"
    echo "2) keys      - Gerar chaves SSH"
    echo "3) ssh       - Configurar SSH"
    echo "4) casaos    - Instalar CasaOS"
    echo "5) test      - Testar conexões"
    echo "6) cleanup   - Limpar ambiente"
    echo "7) full      - Executar setup completo"
    echo "8) status    - Verificar status do container"
    echo "9) logs      - Ver logs do container"
    echo "0) exit      - Sair"
    echo ""
    echo -e "${CYAN}========================================${NC}"
}

# Função para executar script
run_script() {
    local script_name=$1
    local script_path="${SCRIPTS_DIR}/${script_name}"
    
    if [[ ! -f "$script_path" ]]; then
        log "ERROR" "Script não encontrado: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        log "WARNING" "Tornando script executável: $script_path"
        chmod +x "$script_path"
    fi
    
    log "STEP" "Executando: $script_name"
    bash "$script_path"
}

# Função para verificar status do container
check_container_status() {
    if docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "$CONTAINER_NAME"; then
        log "INFO" "Container encontrado:"
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$CONTAINER_NAME"
        
        if docker ps --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
            log "SUCCESS" "Container está rodando"
            return 0
        else
            log "WARNING" "Container existe mas não está rodando"
            return 1
        fi
    else
        log "WARNING" "Container não encontrado"
        return 1
    fi
}

# Função para setup completo
full_setup() {
    log "STEP" "Iniciando setup completo do ambiente de testes"
    
    # Verificar dependências
    check_dependencies
    
    # Criar container
    run_script "create_container.sh"
    
    # Gerar chaves SSH
    run_script "generate-temp-key.sh"
    
    # Configurar SSH
    run_script "setup-ssh.sh"
    
    # Instalar CasaOS
    run_script "install_casaos.sh"
    
    # Testar conexões
    run_script "test_connection.sh"
    
    log "SUCCESS" "Setup completo finalizado!"
    log "INFO" "Container: $CONTAINER_NAME"
    log "INFO" "SSH: localhost:$SSH_PORT"
    log "INFO" "CasaOS: http://localhost:$HTTP_PORT"
}

# Função para mostrar logs do container
show_logs() {
    if check_container_status; then
        log "STEP" "Mostrando logs do container..."
        docker logs "$CONTAINER_NAME" --tail 50 -f
    else
        log "ERROR" "Container não está rodando"
    fi
}

# Função principal
main() {
    # Verificar se scripts directory existe
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        log "ERROR" "Diretório de scripts não encontrado: $SCRIPTS_DIR"
        exit 1
    fi
    
    # Se argumentos foram passados, executar em modo CLI
    if [[ $# -gt 0 ]]; then
        case $1 in
            "create")
                check_dependencies
                run_script "create_container.sh"
                ;;
            "keys")
                run_script "generate-temp-key.sh"
                ;;
            "ssh")
                run_script "setup-ssh.sh"
                ;;
            "casaos")
                run_script "install_casaos.sh"
                ;;
            "test")
                run_script "test_connection.sh"
                ;;
            "cleanup")
                run_script "cleanup.sh"
                ;;
            "full")
                full_setup
                ;;
            "status")
                check_container_status
                ;;
            "logs")
                show_logs
                ;;
            *)
                log "ERROR" "Comando inválido: $1"
                echo "Comandos disponíveis: create, keys, ssh, casaos, test, cleanup, full, status, logs"
                exit 1
                ;;
        esac
        exit 0
    fi
    
    # Modo interativo
    while true; do
        show_menu
        read -p "Digite sua escolha: " choice
        
        case $choice in
            1|create)
                check_dependencies
                run_script "create_container.sh"
                ;;
            2|keys)
                run_script "generate-temp-key.sh"
                ;;
            3|ssh)
                run_script "setup-ssh.sh"
                ;;
            4|casaos)
                run_script "install_casaos.sh"
                ;;
            5|test)
                run_script "test_connection.sh"
                ;;
            6|cleanup)
                run_script "cleanup.sh"
                ;;
            7|full)
                full_setup
                ;;
            8|status)
                check_container_status
                ;;
            9|logs)
                show_logs
                ;;
            0|exit)
                log "INFO" "Saindo..."
                exit 0
                ;;
            *)
                log "ERROR" "Opção inválida. Tente novamente."
                ;;
        esac
        
        echo ""
        read -p "Pressione Enter para continuar..."
    done
}

# Executar função principal
main "$@"
