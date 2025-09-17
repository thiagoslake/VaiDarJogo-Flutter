# VaiDarJogo - Aplicativo Flutter

Este é o aplicativo móvel Flutter do sistema VaiDarJogo, responsável pela interface do usuário e funcionalidades do cliente.

## 📱 Sobre o Aplicativo

O aplicativo Flutter permite que usuários:
- Se registrem e façam login no sistema
- Visualizem e gerenciem jogos
- Configurem notificações
- Administrem perfis de jogadores
- Acessem painéis administrativos

## 🚀 Tecnologias Utilizadas

- **Flutter** - Framework de desenvolvimento móvel
- **Dart** - Linguagem de programação
- **Supabase** - Backend como serviço (autenticação e banco de dados)
- **Google Places API** - Integração com serviços de localização

## 📁 Estrutura do Projeto

```
lib/
├── config/           # Configurações do Supabase e Google Places
├── models/           # Modelos de dados (Player, User)
├── providers/        # Gerenciamento de estado (Auth, Game Status)
├── screens/          # Telas da aplicação
├── services/         # Serviços (Auth, Places, Player, Session)
├── utils/            # Utilitários e tratamento de erros
└── widgets/          # Componentes reutilizáveis
```

## 🛠️ Configuração e Instalação

1. **Pré-requisitos:**
   - Flutter SDK instalado
   - Dart SDK
   - Android Studio ou VS Code com extensões Flutter

2. **Instalação:**
   ```bash
   cd VaiDarJogo_Flutter
   flutter pub get
   ```

3. **Configuração:**
   - Configure as credenciais do Supabase em `lib/config/supabase_config.dart`
   - Configure a API do Google Places em `lib/config/google_places_config.dart`

4. **Execução:**
   ```bash
   flutter run
   ```

## 📱 Plataformas Suportadas

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## 🔧 Funcionalidades Principais

- **Autenticação:** Login e registro de usuários
- **Gestão de Jogos:** Criação, edição e visualização de jogos
- **Notificações:** Configuração e gerenciamento de notificações
- **Perfis:** Gerenciamento de perfis de jogadores
- **Administração:** Painel administrativo para gestão do sistema

## 📚 Documentação Adicional

- `AUTHENTICATION_README.md` - Guia de autenticação
- `GOOGLE_PLACES_SETUP.md` - Configuração do Google Places
- `MIGRATION_SUMMARY.md` - Resumo de migrações
- `QUICK_START_GUIDE.md` - Guia de início rápido

## 🔗 Integração com o Motor

Este aplicativo se conecta com o **VaiDarJogo_Motor** (backend) através de:
- API REST do Supabase
- WebSockets para notificações em tempo real
- Autenticação JWT

## 📞 Suporte

Para dúvidas ou problemas, consulte a documentação ou entre em contato com a equipe de desenvolvimento.