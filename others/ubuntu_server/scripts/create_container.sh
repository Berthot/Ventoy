#!/bin/bash

# Script para criar container Ubuntu Server para testes
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
CONTAINER_IMAGE="ubuntu:22.04"
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

# Função para verificar se container já existe
check_existing_container() {
    if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "WARNING" "Container '$CONTAINER_NAME' já existe"
        
        if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            log "INFO" "Container está rodando. Parando..."
            docker stop "$CONTAINER_NAME"
        fi
        
        log "INFO" "Removendo container existente..."
        docker rm "$CONTAINER_NAME"
    fi
}

# Função para criar o container
create_container() {
    log "STEP" "Criando container Ubuntu Server..."
    
    # Verificar se imagem existe, se não, baixar
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${CONTAINER_IMAGE}$"; then
        log "INFO" "Baixando imagem Ubuntu 22.04..."
        docker pull "$CONTAINER_IMAGE"
    fi
    
    # Criar container
    log "INFO" "Criando container com as seguintes configurações:"
    log "INFO" "  Nome: $CONTAINER_NAME"
    log "INFO" "  Imagem: $CONTAINER_IMAGE"
    log "INFO" "  Portas: SSH=$SSH_PORT, HTTP=$HTTP_PORT, HTTPS=$HTTPS_PORT"
    
    docker run -d \
        --name "$CONTAINER_NAME" \
        --hostname ubuntu-server-test \
        -p "$SSH_PORT:22" \
        -p "$HTTP_PORT:80" \
        -p "$HTTPS_PORT:443" \
        -e DEBIAN_FRONTEND=noninteractive \
        "$CONTAINER_IMAGE" \
        /bin/bash -c "while true; do sleep 30; done"
    
    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "Container criado com sucesso!"
    else
        log "ERROR" "Falha ao criar container"
        exit 1
    fi
}

# Função para configurar o sistema base
setup_base_system() {
    log "STEP" "Configurando sistema base..."
    
    # Atualizar sistema
    log "INFO" "Atualizando sistema..."
    docker exec "$CONTAINER_NAME" apt-get update -y
    docker exec "$CONTAINER_NAME" apt-get upgrade -y
    
    # Instalar pacotes essenciais
    log "INFO" "Instalando pacotes essenciais..."
    docker exec "$CONTAINER_NAME" apt-get install -y \
        openssh-server \
        curl \
        wget \
        nano \
        vim \
        htop \
        net-tools \
        iputils-ping \
        sudo \
        systemd \
        systemd-sysv
    
    # Configurar SSH
    log "INFO" "Configurando SSH Server..."
    docker exec "$CONTAINER_NAME" bash -c "
        # Criar diretório SSH se não existir
        mkdir -p /var/run/sshd
        
        # Configurar SSH
        echo 'Port 22' > /etc/ssh/sshd_config
        echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
        echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
        echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config
        echo 'AuthorizedKeysFile .ssh/authorized_keys' >> /etc/ssh/sshd_config
        
        # Definir senha para root
        echo 'root:test123' | chpasswd
        
        # Criar usuário de teste
        useradd -m -s /bin/bash testuser
        echo 'testuser:test123' | chpasswd
        usermod -aG sudo testuser
        
        # Criar diretório .ssh para testuser
        mkdir -p /home/testuser/.ssh
        chown testuser:testuser /home/testuser/.ssh
        chmod 700 /home/testuser/.ssh
    "
    
    # Iniciar SSH
    log "INFO" "Iniciando serviço SSH..."
    docker exec "$CONTAINER_NAME" service ssh start
    
    # Configurar para iniciar SSH automaticamente
    docker exec "$CONTAINER_NAME" bash -c "
        echo '#!/bin/bash' > /startup.sh
        echo 'service ssh start' >> /startup.sh
        echo 'while true; do sleep 30; done' >> /startup.sh
        chmod +x /startup.sh
    "
    
    log "SUCCESS" "Sistema base configurado com sucesso!"
}

# Função para verificar se container está funcionando
verify_container() {
    log "STEP" "Verificando se container está funcionando..."
    
    # Verificar se container está rodando
    if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "ERROR" "Container não está rodando"
        return 1
    fi
    
    # Verificar conectividade
    log "INFO" "Testando conectividade..."
    if docker exec "$CONTAINER_NAME" ping -c 1 8.8.8.8 &> /dev/null; then
        log "SUCCESS" "Conectividade de rede OK"
    else
        log "WARNING" "Problemas de conectividade detectados"
    fi
    
    # Verificar SSH
    log "INFO" "Testando porta SSH..."
    sleep 2
    if docker exec "$CONTAINER_NAME" netstat -tlnp | grep -q ":22 "; then
        log "SUCCESS" "SSH Server está rodando na porta 22"
    else
        log "WARNING" "SSH Server pode não estar funcionando corretamente"
    fi
    
    # Mostrar informações do container
    log "INFO" "Informações do container:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$CONTAINER_NAME"
    
    log "SUCCESS" "Container verificado com sucesso!"
}

# Função para mostrar informações de acesso
show_access_info() {
    echo ""
    log "INFO" "=== INFORMAÇÕES DE ACESSO ==="
    echo ""
    echo -e "${GREEN}Container:${NC} $CONTAINER_NAME"
    echo -e "${GREEN}SSH:${NC} ssh root@localhost -p $SSH_PORT (senha: test123)"
    echo -e "${GREEN}SSH:${NC} ssh testuser@localhost -p $SSH_PORT (senha: test123)"
    echo -e "${GREEN}HTTP:${NC} http://localhost:$HTTP_PORT (após instalar CasaOS)"
    echo -e "${GREEN}HTTPS:${NC} https://localhost:$HTTPS_PORT (após instalar CasaOS)"
    echo ""
    echo -e "${YELLOW}Comandos úteis:${NC}"
    echo "  docker exec -it $CONTAINER_NAME bash"
    echo "  docker logs $CONTAINER_NAME"
    echo "  docker stop $CONTAINER_NAME"
    echo "  docker start $CONTAINER_NAME"
    echo ""
}

# Função principal
main() {
    log "STEP" "Iniciando criação do container Ubuntu Server..."
    
    # Verificar se Docker está rodando
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker não está rodando. Inicie o serviço Docker primeiro."
        exit 1
    fi
    
    # Verificar se container já existe
    check_existing_container
    
    # Criar container
    create_container
    
    # Configurar sistema base
    setup_base_system
    
    # Verificar container
    verify_container
    
    # Mostrar informações de acesso
    show_access_info
    
    log "SUCCESS" "Container Ubuntu Server criado e configurado com sucesso!"
    log "INFO" "Próximos passos:"
    log "INFO" "  1. Execute './ubuntu_server.sh keys' para gerar chaves SSH"
    log "INFO" "  2. Execute './ubuntu_server.sh ssh' para configurar SSH"
    log "INFO" "  3. Execute './ubuntu_server.sh casaos' para instalar CasaOS"
    log "INFO" "  4. Execute './ubuntu_server.sh test' para testar conexões"
}

# Executar função principal
main "$@"
