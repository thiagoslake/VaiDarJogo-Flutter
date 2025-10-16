# 🚨 Correção do Erro 403 - Autorização no Supabase

## 🎯 **Problema Identificado:**

Erro 403 (Forbidden) indica que as políticas RLS (Row Level Security) não estão configuradas corretamente para o bucket `profile-images`.

## 🔧 **Solução Passo a Passo:**

### **Passo 1: Executar Script SQL**

1. **Abra o Supabase Dashboard**
2. **Vá para SQL Editor**
3. **Execute o arquivo:** `database/fix_403_error.sql`

### **Passo 2: Verificar Configurações**

#### **2.1. Verificar Bucket:**
```sql
SELECT * FROM storage.buckets WHERE id = 'profile-images';
```

**Resultado esperado:**
- `id`: profile-images
- `name`: profile-images  
- `public`: true
- `file_size_limit`: 5242880
- `allowed_mime_types`: ["image/jpeg", "image/png", "image/webp"]

#### **2.2. Verificar Políticas RLS:**
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%profile%';
```

**Resultado esperado:**
- 4 políticas criadas (INSERT, SELECT, UPDATE, DELETE)
- Todas com `permissive`: true
- Todas com `roles`: {authenticated}

#### **2.3. Verificar Campo na Tabela Users:**
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'profile_image_url';
```

**Resultado esperado:**
- `column_name`: profile_image_url
- `data_type`: text

### **Passo 3: Testar no App**

#### **3.1. Verificar Autenticação:**
```
1. Faça login no app
2. Verifique se está autenticado
3. Tente fazer upload de uma foto
```

#### **3.2. Verificar Logs:**
```
📤 Upload iniciado...
✅ Upload concluído
✅ Foto atualizada!
```

## 🔍 **Diagnóstico de Problemas:**

### **Se o Bucket Não Existe:**
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

### **Se as Políticas Não Existem:**
```sql
-- Criar políticas manualmente
CREATE POLICY "Enable upload for authenticated users" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Enable read access for all users" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-images');
```

### **Se o Campo Não Existe:**
```sql
-- Adicionar campo manualmente
ALTER TABLE users ADD COLUMN profile_image_url TEXT;
```

## 🚨 **Problemas Comuns e Soluções:**

### **Erro: "Bucket not found"**
- **Causa:** Bucket não foi criado
- **Solução:** Executar script de criação do bucket

### **Erro: "Permission denied"**
- **Causa:** Políticas RLS não configuradas
- **Solução:** Executar script de políticas RLS

### **Erro: "Column does not exist"**
- **Causa:** Campo profile_image_url não existe
- **Solução:** Adicionar campo na tabela users

### **Erro: "User not authenticated"**
- **Causa:** Usuário não está logado
- **Solução:** Fazer login no app

## 🧪 **Teste Completo:**

### **1. Teste de Configuração:**
```sql
-- Verificar tudo de uma vez
SELECT 
  'Bucket' as tipo,
  CASE WHEN EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'profile-images') 
       THEN 'OK' ELSE 'ERRO' END as status
UNION ALL
SELECT 
  'Políticas' as tipo,
  CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage') >= 4
       THEN 'OK' ELSE 'ERRO' END as status
UNION ALL
SELECT 
  'Campo' as tipo,
  CASE WHEN EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'profile_image_url')
       THEN 'OK' ELSE 'ERRO' END as status;
```

### **2. Teste de Upload:**
```
1. Selecionar imagem
2. Escolher "Upload para Supabase"
3. Verificar logs
4. Confirmar sucesso
```

## 📱 **Resultado Esperado:**

Após executar o script, o upload deve funcionar:

```
📤 Upload iniciado...
✅ Upload concluído
✅ Foto atualizada!
```

## 🎉 **Conclusão:**

O erro 403 é causado por configurações incorretas de RLS. Após executar o script SQL, o problema deve ser resolvido.

**Próximos passos:**
1. **Executar script SQL** no Supabase
2. **Verificar configurações** 
3. **Testar upload** no app
4. **Confirmar funcionamento**

A solução está pronta para resolver o erro 403!

