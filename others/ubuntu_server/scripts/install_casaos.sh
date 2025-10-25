#!/bin/bash

# Script para instalar CasaOS no container Ubuntu Server
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

# Função para verificar se container existe e está rodando
check_container() {
    if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "ERROR" "Container '$CONTAINER_NAME' não está rodando"
        log "INFO" "Execute './ubuntu_server.sh create' primeiro"
        exit 1
    fi
    
    log "SUCCESS" "Container encontrado e rodando"
}

# Função para instalar dependências necessárias
install_dependencies() {
    log "STEP" "Instalando dependências para CasaOS..."
    
    # Atualizar sistema
    log "INFO" "Atualizando sistema..."
    docker exec "$CONTAINER_NAME" apt-get update -y
    
    # Instalar dependências
    log "INFO" "Instalando dependências necessárias..."
    docker exec "$CONTAINER_NAME" apt-get install -y \
        curl \
        wget \
        gnupg \
        lsb-release \
        ca-certificates \
        software-properties-common \
        apt-transport-https \
        nginx \
        ufw
    
    log "SUCCESS" "Dependências instaladas com sucesso"
}

# Função para instalar Docker no container
install_docker() {
    log "STEP" "Instalando Docker no container..."
    
    # Adicionar repositório Docker
    log "INFO" "Adicionando repositório Docker..."
    docker exec "$CONTAINER_NAME" bash -c "
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null
    "
    
    # Atualizar e instalar Docker
    log "INFO" "Instalando Docker..."
    docker exec "$CONTAINER_NAME" apt-get update -y
    docker exec "$CONTAINER_NAME" apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Iniciar Docker
    log "INFO" "Iniciando serviço Docker..."
    docker exec "$CONTAINER_NAME" service docker start
    
    # Adicionar usuário testuser ao grupo docker
    docker exec "$CONTAINER_NAME" usermod -aG docker testuser
    
    log "SUCCESS" "Docker instalado com sucesso"
}

# Função para instalar CasaOS
install_casaos() {
    log "STEP" "Instalando CasaOS..."
    
    # Baixar e executar script de instalação do CasaOS
    log "INFO" "Baixando script de instalação do CasaOS..."
    docker exec "$CONTAINER_NAME" bash -c "
        curl -fsSL https://get.casaos.io | bash
    "
    
    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "CasaOS instalado com sucesso!"
    else
        log "ERROR" "Falha na instalação do CasaOS"
        exit 1
    fi
}

# Função para configurar Nginx
configure_nginx() {
    log "STEP" "Configurando Nginx para CasaOS..."
    
    # Parar Nginx padrão
    docker exec "$CONTAINER_NAME" service nginx stop
    
    # Configurar proxy reverso para CasaOS
    docker exec "$CONTAINER_NAME" bash -c "
        cat > /etc/nginx/sites-available/casaos << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        
        # Habilitar site
        ln -sf /etc/nginx/sites-available/casaos /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
        
        # Testar configuração
        nginx -t
    "
    
    # Iniciar Nginx
    docker exec "$CONTAINER_NAME" service nginx start
    
    log "SUCCESS" "Nginx configurado com sucesso"
}

# Função para configurar firewall
configure_firewall() {
    log "STEP" "Configurando firewall..."
    
    docker exec "$CONTAINER_NAME" bash -c "
        # Configurar UFW
        ufw --force reset
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
    "
    
    log "SUCCESS" "Firewall configurado com sucesso"
}

# Função para verificar instalação
verify_installation() {
    log "STEP" "Verificando instalação do CasaOS..."
    
    # Aguardar CasaOS inicializar
    log "INFO" "Aguardando CasaOS inicializar..."
    sleep 10
    
    # Verificar se CasaOS está rodando
    if docker exec "$CONTAINER_NAME" netstat -tlnp | grep -q ":80 "; then
        log "SUCCESS" "CasaOS está rodando na porta 80"
    else
        log "WARNING" "CasaOS pode não estar rodando corretamente"
    fi
    
    # Verificar se Nginx está rodando
    if docker exec "$CONTAINER_NAME" netstat -tlnp | grep -q ":80.*nginx"; then
        log "SUCCESS" "Nginx está rodando e servindo CasaOS"
    else
        log "WARNING" "Nginx pode não estar configurado corretamente"
    fi
    
    # Testar conectividade HTTP
    log "INFO" "Testando conectividade HTTP..."
    if docker exec "$CONTAINER_NAME" curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200"; then
        log "SUCCESS" "CasaOS está respondendo via HTTP"
    else
        log "WARNING" "CasaOS pode não estar respondendo corretamente"
    fi
}

# Função para mostrar informações de acesso
show_access_info() {
    echo ""
    log "INFO" "=== CASAOS INSTALADO COM SUCESSO ==="
    echo ""
    echo -e "${GREEN}URL de Acesso:${NC} http://localhost:$HTTP_PORT"
    echo -e "${GREEN}URL de Acesso:${NC} https://localhost:$HTTPS_PORT"
    echo ""
    echo -e "${YELLOW}Informações importantes:${NC}"
    echo "  - CasaOS está rodando no container Ubuntu Server"
    echo "  - Acesso via navegador: http://localhost:$HTTP_PORT"
    echo "  - Primeira configuração será solicitada no primeiro acesso"
    echo "  - Container: $CONTAINER_NAME"
    echo ""
    echo -e "${YELLOW}Comandos úteis:${NC}"
    echo "  docker exec -it $CONTAINER_NAME bash"
    echo "  docker logs $CONTAINER_NAME"
    echo "  docker exec $CONTAINER_NAME systemctl status casaos"
    echo ""
}

# Função para configurar auto-start
configure_autostart() {
    log "STEP" "Configurando auto-start dos serviços..."
    
    docker exec "$CONTAINER_NAME" bash -c "
        # Configurar para iniciar serviços automaticamente
        cat > /startup.sh << 'EOF'
#!/bin/bash
service docker start
service ssh start
service nginx start
service casaos start
while true; do sleep 30; done
EOF
        
        chmod +x /startup.sh
        
        # Configurar systemd para CasaOS (se disponível)
        if command -v systemctl &> /dev/null; then
            systemctl enable casaos 2>/dev/null || true
        fi
    "
    
    log "SUCCESS" "Auto-start configurado"
}

# Função principal
main() {
    log "STEP" "Iniciando instalação do CasaOS..."
    
    # Verificar container
    check_container
    
    # Instalar dependências
    install_dependencies
    
    # Instalar Docker
    install_docker
    
    # Instalar CasaOS
    install_casaos
    
    # Configurar Nginx
    configure_nginx
    
    # Configurar firewall
    configure_firewall
    
    # Configurar auto-start
    configure_autostart
    
    # Verificar instalação
    verify_installation
    
    # Mostrar informações de acesso
    show_access_info
    
    log "SUCCESS" "CasaOS instalado e configurado com sucesso!"
    log "INFO" "Próximos passos:"
    log "INFO" "  1. Acesse http://localhost:$HTTP_PORT no navegador"
    log "INFO" "  2. Execute './ubuntu_server.sh test' para testar conexões"
    log "INFO" "  3. Execute './ubuntu_server.sh cleanup' para limpar ambiente"
}

# Executar função principal
main "$@"
