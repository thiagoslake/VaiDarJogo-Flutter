# Configuração da Foto de Perfil

## 📋 Pré-requisitos

Para que a funcionalidade de foto de perfil funcione corretamente, é necessário configurar o Supabase Storage.

## 🗄️ Configuração do Supabase Storage

### ⚡ Configuração Automática (Recomendado)

Execute o script SQL completo no **SQL Editor** do Supabase:

```bash
# Execute o arquivo: database/setup_profile_images.sql
```

Este script configura automaticamente:
- ✅ Bucket `profile-images`
- ✅ Políticas RLS
- ✅ Campo `profile_image_url` na tabela `users`
- ✅ Função de limpeza de fotos antigas
- ✅ Índices para performance

### 🔧 Configuração Manual

Se preferir configurar manualmente:

#### 1. Criar o Bucket

No painel do Supabase, vá para **Storage** e crie um novo bucket:

- **Nome do bucket:** `profile-images`
- **Público:** ✅ Sim (para permitir acesso às imagens)
- **File size limit:** 5MB (recomendado)
- **Allowed MIME types:** `image/jpeg`, `image/png`, `image/webp`

#### 2. Adicionar Campo na Tabela Users

```sql
ALTER TABLE users ADD COLUMN profile_image_url TEXT;
```

#### 3. Configurar Políticas RLS

Execute as políticas do arquivo `database/setup_profile_images.sql`

## 🔧 Configuração do Código

### Verificar Configuração

O código já está configurado para usar o bucket `profile-images`. Se você quiser usar um nome diferente, altere em:

```dart
// Em user_profile_screen.dart, linha ~248
.from('profile-images')  // Altere aqui se necessário
```

### Testar a Funcionalidade

1. **Selecionar Imagem:** Toque no ícone de câmera
2. **Escolher Opção:** 
   - "Upload para Supabase" - Para produção
   - "Salvar Localmente" - Para desenvolvimento/teste
3. **Verificar Logs:** Os logs no console mostrarão o progresso do upload

## 🐛 Solução de Problemas

### Erro: "Bucket não encontrado"
- Verifique se o bucket `profile-images` foi criado no Supabase
- Confirme se o nome está correto (case-sensitive)

### Erro: "Permissão negada"
- Verifique se as políticas RLS estão configuradas corretamente
- Confirme se o usuário está autenticado

### Erro: "Arquivo muito grande"
- Reduza o tamanho da imagem antes do upload
- Ajuste o limite de tamanho no bucket

### Erro: "Tipo de arquivo não permitido"
- Use apenas imagens (JPEG, PNG, WebP)
- Verifique as configurações de MIME types do bucket

## 📱 Funcionalidades Implementadas

- ✅ Seleção de imagem da galeria
- ✅ Otimização automática (512x512px, 80% qualidade)
- ✅ Upload para Supabase Storage
- ✅ Atualização do banco de dados
- ✅ Sincronização com estado da aplicação
- ✅ Tratamento de erros robusto
- ✅ Modo de desenvolvimento (salvar localmente)
- ✅ Logs detalhados para debug

## 🎯 Próximos Passos

1. Configure o Supabase Storage conforme as instruções acima
2. Teste a funcionalidade com uma imagem
3. Verifique os logs para confirmar que tudo está funcionando
4. Em caso de problemas, use a opção "Salvar Localmente" para desenvolvimento

## 📞 Suporte

Se encontrar problemas:

1. Verifique os logs no console
2. Confirme a configuração do Supabase
3. Teste com a opção "Salvar Localmente" primeiro
4. Verifique se o usuário está autenticado
