-- =====================================================
-- CONFIGURAÇÃO DO SUPABASE STORAGE PARA FOTOS DE PERFIL
-- =====================================================

-- 1. Criar o bucket para fotos de perfil
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  5242880, -- 5MB em bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- 2. Adicionar campo profile_image_url na tabela users (se não existir)
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

-- 3. Políticas RLS para o bucket profile-images

-- Política para permitir que usuários façam upload de suas próprias fotos
CREATE POLICY "Users can upload their own profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Política para permitir leitura pública das fotos de perfil
CREATE POLICY "Profile images are publicly accessible" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-images');

-- Política para permitir que usuários atualizem suas próprias fotos
CREATE POLICY "Users can update their own profile images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Política para permitir que usuários excluam suas próprias fotos
CREATE POLICY "Users can delete their own profile images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 4. Função para limpar fotos antigas quando uma nova é enviada
CREATE OR REPLACE FUNCTION cleanup_old_profile_images()
RETURNS TRIGGER AS $$
BEGIN
  -- Se estamos atualizando o profile_image_url
  IF NEW.profile_image_url IS DISTINCT FROM OLD.profile_image_url THEN
    -- Excluir a foto antiga se existir
    IF OLD.profile_image_url IS NOT NULL THEN
      -- Extrair o nome do arquivo da URL
      DECLARE
        old_file_name TEXT;
      BEGIN
        old_file_name := split_part(OLD.profile_image_url, '/', array_length(string_to_array(OLD.profile_image_url, '/'), 1));
        
        -- Tentar excluir o arquivo antigo
        PERFORM storage.objects.delete('profile-images', old_file_name);
      EXCEPTION
        WHEN OTHERS THEN
          -- Ignorar erros ao excluir arquivos antigos
          NULL;
      END;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Trigger para limpar fotos antigas automaticamente
DROP TRIGGER IF EXISTS trigger_cleanup_old_profile_images ON users;
CREATE TRIGGER trigger_cleanup_old_profile_images
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_old_profile_images();

-- 6. Índice para melhorar performance na busca por profile_image_url
CREATE INDEX IF NOT EXISTS idx_users_profile_image_url ON users(profile_image_url) WHERE profile_image_url IS NOT NULL;

-- =====================================================
-- VERIFICAÇÕES
-- =====================================================

-- Verificar se o bucket foi criado
SELECT * FROM storage.buckets WHERE id = 'profile-images';

-- Verificar se o campo foi adicionado
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'profile_image_url';

-- Verificar as políticas criadas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- =====================================================
-- COMO USAR
-- =====================================================

/*
1. Execute este script no SQL Editor do Supabase
2. Verifique se o bucket 'profile-images' foi criado
3. Teste o upload de uma foto de perfil no app
4. Verifique se a foto aparece corretamente

NOTAS:
- O bucket é público para permitir acesso às imagens
- As políticas RLS garantem que usuários só podem modificar suas próprias fotos
- A função de limpeza remove fotos antigas automaticamente
- O limite de tamanho é 5MB por arquivo
- Tipos de arquivo permitidos: JPEG, PNG, WebP
*/

