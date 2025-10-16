-- =====================================================
-- CORREÇÃO DO ERRO 403 - AUTORIZAÇÃO NO SUPABASE STORAGE
-- =====================================================

-- 1. Verificar se o bucket existe
SELECT * FROM storage.buckets WHERE id = 'profile-images';

-- 2. Se o bucket não existir, criar
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 3. Remover políticas antigas (se existirem)
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Profile images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;

-- 4. Criar políticas RLS corretas para o bucket profile-images

-- Política para INSERT (upload)
CREATE POLICY "Enable upload for authenticated users" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

-- Política para SELECT (download/visualização)
CREATE POLICY "Enable read access for all users" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-images');

-- Política para UPDATE (atualizar arquivo)
CREATE POLICY "Enable update for authenticated users" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

-- Política para DELETE (remover arquivo)
CREATE POLICY "Enable delete for authenticated users" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

-- 5. Verificar se o campo profile_image_url existe na tabela users
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'profile_image_url'
    ) THEN
        ALTER TABLE users ADD COLUMN profile_image_url TEXT;
    END IF;
END $$;

-- 6. Verificar se as políticas foram criadas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%profile%';

-- 7. Testar se o usuário atual tem permissão
SELECT auth.uid() as current_user_id, auth.role() as current_role;

-- =====================================================
-- INSTRUÇÕES DE USO
-- =====================================================

/*
1. Execute este script no SQL Editor do Supabase
2. Verifique se todas as políticas foram criadas
3. Teste o upload de uma foto no app
4. Se ainda houver erro, verifique se o usuário está autenticado

NOTAS IMPORTANTES:
- O bucket deve ser público (public = true)
- As políticas permitem acesso para usuários autenticados
- O campo profile_image_url deve existir na tabela users
- O usuário deve estar logado no app
*/

