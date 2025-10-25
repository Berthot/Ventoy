# Ubuntu Server Docker Test Environment

Sistema completo de testes com Docker para validar configuração SSH e CasaOS sem interferir no sistema atual, usando um script orchestrator principal e scripts modulares.

## 🎯 Objetivo

Criar um ambiente isolado de testes para:
- Validar configurações SSH com chaves
- Testar instalação e funcionamento do CasaOS
- Verificar conectividade e portas
- Desenvolver e testar scripts de automação
- Ambiente totalmente isolado e fácil de limpar

## 📁 Estrutura do Projeto

```
/media/bertho/Ventoy/others/ubuntu_server/
├── ubuntu_server.sh          # Orchestrator principal
├── scripts/
│   ├── create_container.sh   # Criar container Docker
│   ├── setup-ssh.sh         # Configurar SSH com chaves (existente)
│   ├── generate-temp-key.sh  # Gerar chaves SSH (existente)
│   ├── install_casaos.sh   # Instalar CasaOS
│   ├── test_connection.sh  # Testar conexões
│   └── cleanup.sh          # Limpar ambiente
└── README.md               # Esta documentação
```

## 🚀 Pré-requisitos

### Sistema
- Linux (testado em Ubuntu/Debian)
- Docker instalado e rodando
- Acesso sudo (para algumas operações)

### Verificar Docker
```bash
# Verificar se Docker está instalado
docker --version

# Verificar se Docker está rodando
docker info
```

### Instalar Docker (se necessário)
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Reiniciar sessão ou executar:
newgrp docker
```

## 🛠️ Instalação e Uso

### 1. Navegar para o diretório
```bash
cd /media/bertho/Ventoy/others/ubuntu_server
```

### 2. Tornar scripts executáveis
```bash
chmod +x ubuntu_server.sh
chmod +x scripts/*.sh
```

### 3. Executar o orchestrator
```bash
./ubuntu_server.sh
```

## 🚀 Configuração do Ubuntu Server Real

Após instalar o Ubuntu Server, use o script interativo:

```bash
cd /media/bertho/Ventoy/others/ubuntu_server/scripts
./setup-ubuntu-server.sh
```

### Características do Script
- **Detecção automática de IP** (com confirmação)
- **Usuário padrão**: `matheus.bertho`
- **Menu interativo** com 5 opções
- **Logs coloridos** e informativos
- **Backup automático** das chaves

### Menu do Script
```
1) Gerar chaves SSH
2) Configurar SSH no servidor
3) Conectar ao servidor
4) Fazer backup das chaves
5) Verificar status da conexão
0) Sair
```

### Fluxo Recomendado
1. **Gerar chaves SSH** (opção 1)
2. **Configurar SSH** (opção 2) - detecta IP automaticamente
3. **Verificar status** (opção 5) - testa conexão
4. **Conectar ao servidor** (opção 3) - acesso direto

## 📋 Comandos Disponíveis

### Menu Interativo
Execute `./ubuntu_server.sh` para acessar o menu interativo com as seguintes opções:

1. **create** - Criar container Ubuntu Server
2. **keys** - Gerar chaves SSH
3. **ssh** - Configurar SSH
4. **casaos** - Instalar CasaOS
5. **test** - Testar conexões
6. **cleanup** - Limpar ambiente
7. **full** - Executar setup completo
8. **status** - Verificar status do container
9. **logs** - Ver logs do container

### Modo CLI
Execute comandos diretamente:

```bash
# Criar container
./ubuntu_server.sh create

# Gerar chaves SSH
./ubuntu_server.sh keys

# Configurar SSH
./ubuntu_server.sh ssh

# Instalar CasaOS
./ubuntu_server.sh casaos

# Testar conexões
./ubuntu_server.sh test

# Setup completo
./ubuntu_server.sh full

# Limpar ambiente
./ubuntu_server.sh cleanup

# Verificar status
./ubuntu_server.sh status

# Ver logs
./ubuntu_server.sh logs
```

## 🔧 Configurações

### Container
- **Nome**: `ubuntu-server-test`
- **Imagem**: `ubuntu:22.04`
- **Hostname**: `ubuntu-server-test`

### Portas
- **SSH**: `2222:22`
- **HTTP**: `8080:80`
- **HTTPS**: `8443:443`

### Usuários
- **root**: senha `test123`
- **testuser**: senha `test123` (com sudo)

## 📊 Fluxo de Trabalho

### Fase 1: Testes com Docker (Sistema Atual)
```bash
./ubuntu_server.sh full
```

Este comando executa automaticamente:
1. ✅ Verificar dependências (Docker)
2. ✅ Criar container Ubuntu Server
3. ✅ Gerar chaves SSH
4. ✅ Configurar SSH
5. ✅ Instalar CasaOS
6. ✅ Testar conexões

### Fase 2: Configuração do Ubuntu Server Real
```bash
cd /media/bertho/Ventoy/others/ubuntu_server/scripts
./setup-ubuntu-server.sh
```

Este script interativo oferece:
1. ✅ Gerar chaves SSH
2. ✅ Configurar SSH automaticamente
3. ✅ Conectar ao servidor
4. ✅ Fazer backup das chaves
5. ✅ Verificar status da conexão

### Setup Manual (Passo a Passo)
```bash
# 1. Criar container
./ubuntu_server.sh create

# 2. Gerar chaves SSH
./ubuntu_server.sh keys

# 3. Configurar SSH
./ubuntu_server.sh ssh

# 4. Instalar CasaOS
./ubuntu_server.sh casaos

# 5. Testar conexões
./ubuntu_server.sh test
```

## 🔍 Testes e Validação

### Testes Automáticos
O script `test_connection.sh` executa os seguintes testes:

- ✅ **Conectividade de rede** (ping, DNS)
- ✅ **Porta SSH** (verificação local e host)
- ✅ **Autenticação SSH** (usuário/senha e chaves)
- ✅ **Portas web** (HTTP/HTTPS)
- ✅ **CasaOS** (serviço e acesso web)
- ✅ **Docker no container** (funcionamento interno)

### Testes Manuais
```bash
# SSH com usuário root
ssh root@localhost -p 2222

# SSH com usuário testuser
ssh testuser@localhost -p 2222

# SSH com chave
ssh -i ~/.ssh/id_rsa testuser@localhost -p 2222

# Acesso web CasaOS
curl http://localhost:8080

# Acessar container
docker exec -it ubuntu-server-test bash
```

## 🌐 Acesso aos Serviços

### SSH
```bash
# Usuário root
ssh root@localhost -p 2222
# Senha: test123

# Usuário testuser
ssh testuser@localhost -p 2222
# Senha: test123

# Com chave SSH
ssh -i ~/.ssh/id_rsa testuser@localhost -p 2222
```

### CasaOS
- **URL**: http://localhost:8080
- **Primeira configuração**: Será solicitada no primeiro acesso
- **Interface**: Web-based para gerenciamento de containers

### Container
```bash
# Acessar container
docker exec -it ubuntu-server-test bash

# Ver logs
docker logs ubuntu-server-test

# Status dos serviços
docker exec ubuntu-server-test systemctl status casaos
```

## 🧹 Limpeza

### Limpeza Interativa
```bash
./ubuntu_server.sh cleanup
```

### Limpeza Forçada
```bash
./ubuntu_server.sh cleanup --force
```

### Limpeza Manual
```bash
# Parar container
docker stop ubuntu-server-test

# Remover container
docker rm ubuntu-server-test

# Limpar imagens órfãs
docker rmi $(docker images -f "dangling=true" -q)

# Limpar volumes não utilizados
docker volume rm $(docker volume ls -f "dangling=true" -q)
```

## 🔧 Troubleshooting

### Problemas Comuns

#### Container não inicia
```bash
# Verificar logs
docker logs ubuntu-server-test

# Verificar se porta está em uso
netstat -tlnp | grep :2222
```

#### SSH não conecta
```bash
# Verificar se SSH está rodando no container
docker exec ubuntu-server-test service ssh status

# Verificar porta SSH
docker exec ubuntu-server-test netstat -tlnp | grep :22
```

#### CasaOS não acessível
```bash
# Verificar se CasaOS está rodando
docker exec ubuntu-server-test systemctl status casaos

# Verificar porta HTTP
docker exec ubuntu-server-test netstat -tlnp | grep :80

# Verificar Nginx
docker exec ubuntu-server-test service nginx status
```

#### Docker não funciona no container
```bash
# Verificar se Docker está rodando
docker exec ubuntu-server-test docker info

# Reiniciar Docker no container
docker exec ubuntu-server-test service docker restart
```

### Logs Úteis
```bash
# Logs do container
docker logs ubuntu-server-test

# Logs do CasaOS
docker exec ubuntu-server-test journalctl -u casaos

# Logs do SSH
docker exec ubuntu-server-test journalctl -u ssh

# Logs do Nginx
docker exec ubuntu-server-test journalctl -u nginx
```

## 📈 Monitoramento

### Status do Container
```bash
# Status geral
./ubuntu_server.sh status

# Informações detalhadas
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep ubuntu-server-test
```

### Recursos do Sistema
```bash
# Uso de CPU e memória
docker stats ubuntu-server-test

# Espaço em disco
docker exec ubuntu-server-test df -h
```

## 🔒 Segurança

### Considerações
- ⚠️ **Apenas para testes**: Este ambiente não é seguro para produção
- ⚠️ **Senhas padrão**: Usuários têm senhas simples (`test123`)
- ⚠️ **Portas expostas**: SSH e web estão acessíveis publicamente
- ⚠️ **Firewall**: Configurado para permitir acesso

### Boas Práticas
- ✅ Use apenas em ambiente isolado
- ✅ Limpe o ambiente após os testes
- ✅ Não use em produção
- ✅ Mantenha o Docker atualizado

## 📚 Scripts Detalhados

### ubuntu_server.sh (Orchestrator)
- Menu interativo e modo CLI
- Verificação de dependências
- Logs coloridos e informativos
- Orquestração de todos os scripts

### create_container.sh
- Cria container Ubuntu 22.04
- Expõe portas (2222:22, 8080:80, 8443:443)
- Instala OpenSSH Server
- Cria usuários de teste
- Configura sistema base

### install_casaos.sh
- Instala Docker no container
- Instala CasaOS
- Configura Nginx
- Configura firewall
- Configura auto-start

### test_connection.sh
- Testa conectividade de rede
- Verifica portas SSH e web
- Testa autenticação SSH
- Valida CasaOS
- Testa Docker no container

### cleanup.sh
- Para e remove container
- Limpa chaves SSH de teste
- Remove imagens e volumes órfãos
- Limpa logs
- Verifica limpeza

## 🤝 Contribuição

Para contribuir com melhorias:

1. Teste o ambiente completo
2. Identifique problemas ou melhorias
3. Documente as mudanças
4. Teste novamente após modificações

## 📄 Licença

Este projeto é para uso educacional e de testes. Use com responsabilidade.

---

**Desenvolvido para ambiente de testes Ubuntu Server com CasaOS**