# Ventoy USB Boot Drive - Tema Fallout

## 📋 Descrição
Este é um pendrive USB configurado com Ventoy para boot múltiplo, utilizando o tema **Fallout** para uma experiência visual única e nostálgica.

## 🎨 Tema Fallout
O tema Fallout foi escolhido para dar um visual retrô e pós-aprático ao menu de boot, criando uma atmosfera imersiva que remete ao universo dos jogos Fallout. O tema inclui:

- **Interface visual**: Design inspirado no Pip-Boy dos jogos Fallout
- **Cores**: Paleta de cores verde/âmbar característica da série
- **Fontes**: Tipografia que remete ao estilo retrô-futurista
- **Ícones**: Ícones personalizados para diferentes distribuições Linux e Windows

## 📁 Estrutura do Projeto
```
E:\
├── ISO\                           # ISOs de instalação
│   ├── pop-os_22.04_amd64_intel_58.iso
│   ├── ubuntu-22.04.5-live-server-amd64.iso
│   └── Windows_11_24H2.iso
├── ventoy\                        # Configuração do Ventoy
│   ├── ventoy.json               # Configuração principal
│   ├── ventoy_backup.json        # Backup da configuração
│   └── themes\
│       └── fallout\              # Tema Fallout
│           ├── theme.txt         # Configuração do tema
│           ├── background.png    # Imagem de fundo
│           ├── fixedsys-regular-32.pf2  # Fonte
│           └── icons\            # Ícones das distribuições
└── README.md                     # Este arquivo
```

## 🔧 Configuração Atual
### ISOs Configuradas:
1. **Pop!_OS 22.04 LTS** - Distribuição Linux baseada em Ubuntu
2. **Ubuntu Server 22.04.5 LTS** - Servidor Ubuntu LTS (recomendado para placa ASUS Prime A320M-K/BR)
3. **Windows 11 24H2** - Sistema operacional Microsoft

### Configurações do Ventoy:
- **Idioma**: Português (pt_BR)
- **Tema**: Fallout
- **Modo gráfico**: Máximo (max)
- **Fonte**: Fixedsys Regular 32pt

## 🚀 Como Usar
1. **Boot**: Insira o pendrive e inicie o computador
2. **Menu**: O menu Fallout aparecerá automaticamente
3. **Navegação**: Use as setas do teclado para navegar
4. **Seleção**: Pressione Enter para iniciar a ISO selecionada

## 🔄 Recuperação/Reinstalação
Caso você perca ou corrompa este pendrive, siga estes passos:

### 1. Recriar o Ventoy:
- Baixe o Ventoy mais recente em: https://www.ventoy.net/
- Execute o Ventoy2Disk.exe
- Selecione o pendrive
- Clique em "Install"

### 2. Restaurar a Configuração:
- Copie o arquivo `ventoy.json` para `/ventoy/ventoy.json`
- Copie a pasta `themes/fallout/` para `/ventoy/themes/`
- Reinicie o pendrive

### 3. Adicionar ISOs:
- Copie as ISOs para a pasta `/ISO/`
- Atualize o `ventoy.json` com as novas ISOs

## 📝 Notas Importantes
- **Ubuntu 22.04.5 LTS**: Versão recomendada para compatibilidade com placa ASUS Prime A320M-K/BR
- **Driver r8168-dkms**: Necessário instalar manualmente após instalação do Ubuntu
- **Backup**: Mantenha sempre um backup do `ventoy.json` e das ISOs importantes

## 🎮 Sobre o Tema Fallout
O tema Fallout foi escolhido não apenas por sua estética única, mas também por sua funcionalidade:
- **Legibilidade**: Cores de alto contraste para fácil leitura
- **Nostalgia**: Remete aos clássicos jogos de RPG pós-apocalíptico
- **Personalização**: Fácil de modificar e adaptar

## 📞 Suporte
Para problemas com o Ventoy, consulte a documentação oficial: https://www.ventoy.net/

---
*Criado com ❤️ e muito ☢️ (radiação) - Vault-Tec approved!*
