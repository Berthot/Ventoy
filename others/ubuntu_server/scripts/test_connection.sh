#!/bin/bash

# Script para testar conexões do ambiente Ubuntu Server
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
SSH_PORT="2222"
HTTP_PORT="8080"
HTTPS_PORT="8443"

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

# Função para verificar se container está rodando
check_container() {
    log "STEP" "Verificando status do container..."
    
    if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "ERROR" "Container '$CONTAINER_NAME' não está rodando"
        log "INFO" "Execute './ubuntu_server.sh create' primeiro"
        return 1
    fi
    
    log "SUCCESS" "Container está rodando"
    return 0
}

# Função para testar conectividade de rede
test_network_connectivity() {
    log "STEP" "Testando conectividade de rede..."
    
    # Teste de ping para internet
    log "INFO" "Testando conectividade com internet..."
    if docker exec "$CONTAINER_NAME" ping -c 3 8.8.8.8 &> /dev/null; then
        log "SUCCESS" "Conectividade com internet: OK"
    else
        log "ERROR" "Conectividade com internet: FALHOU"
        return 1
    fi
    
    # Teste de DNS
    log "INFO" "Testando resolução DNS..."
    if docker exec "$CONTAINER_NAME" nslookup google.com &> /dev/null; then
        log "SUCCESS" "Resolução DNS: OK"
    else
        log "ERROR" "Resolução DNS: FALHOU"
        return 1
    fi
    
    return 0
}

# Função para testar porta SSH
test_ssh_port() {
    log "STEP" "Testando porta SSH..."
    
    # Verificar se porta SSH está aberta no container
    log "INFO" "Verificando se SSH está rodando no container..."
    if docker exec "$CONTAINER_NAME" netstat -tlnp | grep -q ":22 "; then
        log "SUCCESS" "SSH Server está rodando no container"
    else
        log "ERROR" "SSH Server não está rodando no container"
        return 1
    fi
    
    # Testar conectividade com porta SSH do host
    log "INFO" "Testando conectividade com porta SSH do host..."
    if nc -z localhost "$SSH_PORT" 2>/dev/null; then
        log "SUCCESS" "Porta SSH $SSH_PORT está acessível do host"
    else
        log "ERROR" "Porta SSH $SSH_PORT não está acessível do host"
        return 1
    fi
    
    return 0
}

# Função para testar autenticação SSH
test_ssh_authentication() {
    log "STEP" "Testando autenticação SSH..."
    
    # Teste com usuário root (senha)
    log "INFO" "Testando autenticação SSH com usuário root..."
    if echo "test123" | sshpass -p "test123" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@localhost -p "$SSH_PORT" "echo 'SSH root test successful'" &> /dev/null; then
        log "SUCCESS" "Autenticação SSH com root: OK"
    else
        log "WARNING" "Autenticação SSH com root: FALHOU (pode ser normal se sshpass não estiver instalado)"
    fi
    
    # Teste com usuário testuser (senha)
    log "INFO" "Testando autenticação SSH com usuário testuser..."
    if echo "test123" | sshpass -p "test123" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 testuser@localhost -p "$SSH_PORT" "echo 'SSH testuser test successful'" &> /dev/null; then
        log "SUCCESS" "Autenticação SSH com testuser: OK"
    else
        log "WARNING" "Autenticação SSH com testuser: FALHOU (pode ser normal se sshpass não estiver instalado)"
    fi
    
    # Verificar se chaves SSH existem
    if [[ -f ~/.ssh/id_rsa && -f ~/.ssh/id_rsa.pub ]]; then
        log "INFO" "Chaves SSH encontradas, testando autenticação por chave..."
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ~/.ssh/id_rsa testuser@localhost -p "$SSH_PORT" "echo 'SSH key test successful'" &> /dev/null; then
            log "SUCCESS" "Autenticação SSH por chave: OK"
        else
            log "WARNING" "Autenticação SSH por chave: FALHOU (chave pode não estar configurada no container)"
        fi
    else
        log "INFO" "Chaves SSH não encontradas. Execute './ubuntu_server.sh keys' para gerar chaves"
    fi
    
    return 0
}

# Função para testar portas HTTP/HTTPS
test_web_ports() {
    log "STEP" "Testando portas web..."
    
    # Testar porta HTTP
    log "INFO" "Testando porta HTTP $HTTP_PORT..."
    if nc -z localhost "$HTTP_PORT" 2>/dev/null; then
        log "SUCCESS" "Porta HTTP $HTTP_PORT está acessível"
        
        # Testar resposta HTTP
        log "INFO" "Testando resposta HTTP..."
        local http_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:"$HTTP_PORT" 2>/dev/null || echo "000")
        if [[ "$http_response" =~ ^[2-3][0-9][0-9]$ ]]; then
            log "SUCCESS" "HTTP responde com código: $http_response"
        else
            log "WARNING" "HTTP responde com código: $http_response"
        fi
    else
        log "WARNING" "Porta HTTP $HTTP_PORT não está acessível"
    fi
    
    # Testar porta HTTPS
    log "INFO" "Testando porta HTTPS $HTTPS_PORT..."
    if nc -z localhost "$HTTPS_PORT" 2>/dev/null; then
        log "SUCCESS" "Porta HTTPS $HTTPS_PORT está acessível"
    else
        log "WARNING" "Porta HTTPS $HTTPS_PORT não está acessível"
    fi
    
    return 0
}

# Função para testar CasaOS
test_casaos() {
    log "STEP" "Testando CasaOS..."
    
    # Verificar se CasaOS está rodando no container
    log "INFO" "Verificando se CasaOS está rodando no container..."
    if docker exec "$CONTAINER_NAME" netstat -tlnp | grep -q ":80 "; then
        log "SUCCESS" "CasaOS está rodando no container"
    else
        log "WARNING" "CasaOS pode não estar rodando no container"
        return 1
    fi
    
    # Testar acesso web ao CasaOS
    log "INFO" "Testando acesso web ao CasaOS..."
    local casaos_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:"$HTTP_PORT" 2>/dev/null || echo "000")
    if [[ "$casaos_response" =~ ^[2-3][0-9][0-9]$ ]]; then
        log "SUCCESS" "CasaOS está acessível via web (código: $casaos_response)"
    else
        log "WARNING" "CasaOS pode não estar acessível via web (código: $casaos_response)"
    fi
    
    # Verificar se Nginx está rodando
    log "INFO" "Verificando se Nginx está rodando..."
    if docker exec "$CONTAINER_NAME" ps aux | grep -q nginx; then
        log "SUCCESS" "Nginx está rodando"
    else
        log "WARNING" "Nginx pode não estar rodando"
    fi
    
    return 0
}

# Função para testar Docker no container
test_docker_in_container() {
    log "STEP" "Testando Docker no container..."
    
    # Verificar se Docker está rodando no container
    log "INFO" "Verificando se Docker está rodando no container..."
    if docker exec "$CONTAINER_NAME" docker info &> /dev/null; then
        log "SUCCESS" "Docker está funcionando no container"
    else
        log "WARNING" "Docker pode não estar funcionando no container"
        return 1
    fi
    
    # Testar comando Docker básico
    log "INFO" "Testando comando Docker básico..."
    if docker exec "$CONTAINER_NAME" docker ps &> /dev/null; then
        log "SUCCESS" "Comando 'docker ps' funcionando"
    else
        log "WARNING" "Comando 'docker ps' falhou"
    fi
    
    return 0
}

# Função para mostrar resumo dos testes
show_test_summary() {
    echo ""
    log "INFO" "=== RESUMO DOS TESTES ==="
    echo ""
    echo -e "${GREEN}Container:${NC} $CONTAINER_NAME"
    echo -e "${GREEN}SSH:${NC} localhost:$SSH_PORT"
    echo -e "${GREEN}HTTP:${NC} http://localhost:$HTTP_PORT"
    echo -e "${GREEN}HTTPS:${NC} https://localhost:$HTTPS_PORT"
    echo ""
    echo -e "${YELLOW}Comandos de teste manual:${NC}"
    echo "  ssh root@localhost -p $SSH_PORT"
    echo "  ssh testuser@localhost -p $SSH_PORT"
    echo "  curl http://localhost:$HTTP_PORT"
    echo "  docker exec -it $CONTAINER_NAME bash"
    echo ""
}

# Função principal
main() {
    log "STEP" "Iniciando testes de conexão..."
    
    local tests_passed=0
    local tests_total=0
    
    # Verificar container
    if check_container; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    # Testar conectividade de rede
    if test_network_connectivity; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    # Testar porta SSH
    if test_ssh_port; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    # Testar autenticação SSH
    if test_ssh_authentication; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    # Testar portas web
    if test_web_ports; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    # Testar CasaOS
    if test_casaos; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    # Testar Docker no container
    if test_docker_in_container; then
        ((tests_passed++))
    fi
    ((tests_total++))
    
    # Mostrar resumo
    show_test_summary
    
    # Resultado final
    echo ""
    if [[ $tests_passed -eq $tests_total ]]; then
        log "SUCCESS" "Todos os testes passaram! ($tests_passed/$tests_total)"
    else
        log "WARNING" "Alguns testes falharam ($tests_passed/$tests_total)"
        log "INFO" "Verifique os logs acima para detalhes"
    fi
    
    echo ""
    log "INFO" "Para mais informações:"
    log "INFO" "  - Logs do container: docker logs $CONTAINER_NAME"
    log "INFO" "  - Acessar container: docker exec -it $CONTAINER_NAME bash"
    log "INFO" "  - Status dos serviços: docker exec $CONTAINER_NAME systemctl status casaos"
}

# Executar função principal
main "$@"
