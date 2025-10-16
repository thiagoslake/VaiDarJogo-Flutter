# 🔧 Debug do Upload de Foto de Perfil

## 🚨 Problema: Erro ao fazer upload da imagem no bucket do Supabase

### ✅ Correções Implementadas:

#### 1. **Validações Robustas**
- ✅ Verificação de tamanho do arquivo (máximo 5MB)
- ✅ Verificação de arquivo vazio
- ✅ Verificação de autenticação do usuário
- ✅ Verificação de inicialização do Supabase

#### 2. **Logs Detalhados**
- ✅ Informações do usuário
- ✅ Caminho do arquivo
- ✅ Tamanho do arquivo
- ✅ Lista de buckets disponíveis
- ✅ Configurações do bucket
- ✅ Número de arquivos no bucket

#### 3. **Método de Upload Simplificado**
- ✅ Uso do método `upload()` padrão
- ✅ Remoção de métodos alternativos complexos
- ✅ Tratamento de erro específico

#### 4. **Função de Teste do Bucket**
- ✅ Botão "Testar Bucket" no dialog
- ✅ Teste de acesso sem upload
- ✅ Verificação de permissões

## 🧪 Como Testar:

### **Passo 1: Testar Acesso ao Bucket**
```
1. Selecionar uma imagem
2. Escolher "Testar Bucket"
3. Verificar logs no console
4. Confirmar se o acesso funciona
```

### **Passo 2: Fazer Upload**
```
1. Selecionar uma imagem
2. Escolher "Upload para Supabase"
3. Verificar logs detalhados
4. Confirmar sucesso ou identificar erro
```

## 📋 Logs Esperados:

### **Sucesso:**
```
📤 Iniciando upload da foto de perfil...
👤 Usuário: 12345678-1234-1234-1234-123456789012
📁 Arquivo: /path/to/image.jpg
📏 Tamanho do arquivo: 123456 bytes (0.12 MB)
📤 Iniciando upload da imagem: profile_123_1234567890.jpg
📁 Caminho do arquivo: /path/to/image.jpg
📦 Buckets disponíveis: [profile-images, other-bucket]
✅ Bucket profile-images encontrado
📋 Configurações do bucket: id=profile-images, name=profile-images, public=true
📁 Arquivos no bucket: 0 arquivos
📤 Fazendo upload do arquivo...
✅ Upload concluído: {path: profile_123_1234567890.jpg}
🔗 URL da imagem gerada: https://...
💾 Atualizando banco de dados...
✅ Banco de dados atualizado com sucesso
```

### **Erro Comum:**
```
❌ Erro detalhado no upload: [detalhes do erro]
❌ Tipo do erro: [tipo específico]
```

## 🔍 Possíveis Problemas e Soluções:

### **1. Erro de Permissão (RLS)**
```
Problema: "permission denied" ou "RLS policy"
Solução: Verificar políticas RLS do bucket
```

### **2. Erro de Autenticação**
```
Problema: "not authenticated" ou "auth"
Solução: Fazer login novamente
```

### **3. Erro de Bucket**
```
Problema: "bucket not found" ou "storage"
Solução: Verificar se bucket existe e está público
```

### **4. Erro de Arquivo**
```
Problema: "file too large" ou "invalid file"
Solução: Usar imagem menor ou formato válido
```

## 🛠️ Verificações no Supabase:

### **1. Bucket Existe?**
- Ir para Storage → Buckets
- Verificar se `profile-images` está listado
- Verificar se está marcado como público

### **2. Políticas RLS Configuradas?**
- Ir para Storage → Policies
- Verificar se há políticas para `profile-images`
- Verificar se permitem INSERT, SELECT, UPDATE, DELETE

### **3. Campo na Tabela Users?**
- Ir para Table Editor → users
- Verificar se existe coluna `profile_image_url`

## 📱 Teste no App:

### **Opção 1: Teste Rápido**
```
1. Selecionar imagem
2. Escolher "Testar Bucket"
3. Ver resultado no SnackBar
```

### **Opção 2: Upload Completo**
```
1. Selecionar imagem
2. Escolher "Upload para Supabase"
3. Ver logs detalhados no console
4. Ver resultado no SnackBar
```

### **Opção 3: Modo Desenvolvimento**
```
1. Selecionar imagem
2. Escolher "Salvar Localmente"
3. Testar interface sem upload
```

## 🚀 Próximos Passos:

1. **Execute o teste do bucket** primeiro
2. **Verifique os logs** no console
3. **Identifique o erro específico** se houver
4. **Use as soluções** correspondentes
5. **Teste o upload completo** após correções

## 📞 Se Ainda Houver Problemas:

1. **Copie os logs completos** do console
2. **Verifique as configurações** do Supabase
3. **Teste com imagem pequena** (menos de 1MB)
4. **Use o modo local** para desenvolvimento

