# 🚨 Políticas RLS Não Aparecem - Solução Específica

## 🎯 **Problema Identificado:**

O comando `SELECT` não retorna nenhuma política, indicando que as políticas RLS não foram criadas corretamente para o bucket `profile-images`.

## 🔧 **Solução Específica:**

### **Passo 1: Executar Script de Correção**

Execute o arquivo: `database/create_storage_policies.sql`

Este script:
- ✅ Verifica se o bucket existe
- ✅ Cria o bucket se necessário
- ✅ Remove políticas antigas
- ✅ Cria políticas específicas
- ✅ Verifica se tudo foi criado

### **Passo 2: Verificar Resultados**

Após executar o script, você deve ver:

#### **2.1. Bucket Criado:**
```
id: profile-images
name: profile-images
public: true
file_size_limit: 5242880
allowed_mime_types: ["image/jpeg", "image/png", "image/webp"]
```

#### **2.2. Políticas Criadas:**
```
schemaname | tablename | policyname                    | permissive | roles        | cmd
-----------|-----------|-------------------------------|------------|--------------|-----
storage    | objects   | profile_images_upload_policy  | true       | {authenticated} | INSERT
storage    | objects   | profile_images_select_policy  | true       | {}           | SELECT
storage    | objects   | profile_images_update_policy  | true       | {authenticated} | UPDATE
storage    | objects   | profile_images_delete_policy  | true       | {authenticated} | DELETE
```

#### **2.3. Campo na Tabela:**
```
column_name: profile_image_url
data_type: text
is_nullable: YES
```

### **Passo 3: Teste Final**

O script deve mostrar:
```
=== TESTE FINAL ===
item                    | status
------------------------|-------
Bucket profile-images   | ✅ OK
Políticas RLS          | ✅ OK
Campo profile_image_url| ✅ OK
Usuário autenticado    | ✅ OK
```

## 🔍 **Se Ainda Não Funcionar:**

### **Problema 1: Tabela storage.objects não existe**
```sql
-- Verificar se a tabela existe
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'storage' 
  AND table_name = 'objects'
) as table_exists;
```

**Se retornar `false`:**
- O Supabase Storage não está habilitado
- Contate o suporte do Supabase

### **Problema 2: Bucket não é criado**
```sql
-- Criar bucket manualmente
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
);
```

### **Problema 3: Políticas não são criadas**
```sql
-- Criar políticas manualmente
CREATE POLICY "profile_images_upload_policy" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "profile_images_select_policy" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-images');
```

## 🧪 **Comandos de Verificação:**

### **Verificar Bucket:**
```sql
SELECT * FROM storage.buckets WHERE id = 'profile-images';
```

### **Verificar Políticas:**
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%profile%';
```

### **Verificar Campo:**
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name = 'profile_image_url';
```

### **Verificar Usuário:**
```sql
SELECT auth.uid() as user_id, auth.role() as role;
```

## 🚨 **Problemas Comuns:**

### **Erro: "relation storage.objects does not exist"**
- **Causa:** Supabase Storage não habilitado
- **Solução:** Habilitar Storage no painel do Supabase

### **Erro: "permission denied for schema storage"**
- **Causa:** Usuário sem permissão
- **Solução:** Executar como superuser ou owner

### **Erro: "policy already exists"**
- **Causa:** Política já existe
- **Solução:** Remover política antiga primeiro

## 📱 **Teste no App:**

Após executar o script:

1. **Faça login no app**
2. **Vá para "Meu Perfil"**
3. **Selecione uma imagem**
4. **Escolha "Upload para Supabase"**
5. **Verifique se funciona**

## 🎉 **Resultado Esperado:**

```
📤 Upload iniciado...
✅ Upload concluído
✅ Foto atualizada!
```

## 🔧 **Script de Emergência:**

Se nada funcionar, execute este script mínimo:

```sql
-- Script de emergência
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-images', 'profile-images', true) 
ON CONFLICT (id) DO UPDATE SET public = true;

CREATE POLICY "allow_all_profile_images" ON storage.objects
FOR ALL USING (bucket_id = 'profile-images');

ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
```

## 🎯 **Conclusão:**

O problema das políticas não aparecerem é resolvido com o script específico. Execute o arquivo `create_storage_policies.sql` e verifique os resultados.

**Próximos passos:**
1. **Executar script** `create_storage_policies.sql`
2. **Verificar resultados** com os comandos de teste
3. **Testar upload** no app
4. **Confirmar funcionamento**

A solução está pronta para resolver o problema das políticas!

