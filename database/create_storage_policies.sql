-- =====================================================
-- CRIAR POLÍTICAS RLS PARA STORAGE - CORREÇÃO ESPECÍFICA
-- =====================================================

-- 1. Primeiro, verificar se o bucket existe
SELECT 'Verificando bucket...' as status;
SELECT * FROM storage.buckets WHERE id = 'profile-images';

-- 2. Se não existir, criar o bucket
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

-- 3. Verificar se a tabela storage.objects existe
SELECT 'Verificando tabela storage.objects...' as status;
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'storage' 
  AND table_name = 'objects'
) as table_exists;

-- 4. Verificar políticas existentes
SELECT 'Políticas existentes:' as status;
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage';

-- 5. Remover TODAS as políticas existentes para o bucket profile-images
DROP POLICY IF EXISTS "Enable upload for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Enable read access for all users" ON storage.objects;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Profile images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;

-- 6. Criar políticas específicas para o bucket profile-images

-- Política para INSERT (upload)
CREATE POLICY "profile_images_upload_policy" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

-- Política para SELECT (download/visualização)
CREATE POLICY "profile_images_select_policy" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-images');

-- Política para UPDATE (atualizar arquivo)
CREATE POLICY "profile_images_update_policy" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

-- Política para DELETE (remover arquivo)
CREATE POLICY "profile_images_delete_policy" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

-- 7. Verificar se as políticas foram criadas
SELECT 'Políticas criadas:' as status;
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%profile%';

-- 8. Verificar se o campo profile_image_url existe na tabela users
SELECT 'Verificando campo profile_image_url...' as status;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name = 'profile_image_url';

-- 9. Se o campo não existir, criar
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'profile_image_url'
    ) THEN
        ALTER TABLE users ADD COLUMN profile_image_url TEXT;
        RAISE NOTICE 'Campo profile_image_url criado na tabela users';
    ELSE
        RAISE NOTICE 'Campo profile_image_url já existe na tabela users';
    END IF;
END $$;

-- 10. Teste final - verificar tudo
SELECT '=== TESTE FINAL ===' as status;

-- Verificar bucket
SELECT 
  'Bucket profile-images' as item,
  CASE WHEN EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'profile-images') 
       THEN '✅ OK' ELSE '❌ ERRO' END as status;

-- Verificar políticas
SELECT 
  'Políticas RLS' as item,
  CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage' AND policyname LIKE '%profile%') >= 4
       THEN '✅ OK' ELSE '❌ ERRO' END as status;

-- Verificar campo
SELECT 
  'Campo profile_image_url' as item,
  CASE WHEN EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'profile_image_url')
       THEN '✅ OK' ELSE '❌ ERRO' END as status;

-- Verificar usuário atual
SELECT 
  'Usuário autenticado' as item,
  CASE WHEN auth.uid() IS NOT NULL 
       THEN '✅ OK' ELSE '❌ ERRO' END as status;

