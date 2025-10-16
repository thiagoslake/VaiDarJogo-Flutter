# 🛠️ Migração: Adicionar Coluna end_date

## Problema
O erro `Could not find the 'end_date' column of 'games' in the schema cache` ocorre porque a coluna `end_date` não existe na tabela `games` no banco de dados, mas o código Flutter está tentando usá-la.

## Solução
Execute o script de migração `migration_add_end_date.sql` no Supabase SQL Editor.

## Como Executar

1. **Acesse o Supabase Dashboard**
   - Vá para [supabase.com](https://supabase.com)
   - Faça login na sua conta
   - Selecione seu projeto

2. **Abra o SQL Editor**
   - No menu lateral, clique em "SQL Editor"
   - Clique em "New query"

3. **Execute o Script**
   - Copie o conteúdo do arquivo `migration_add_end_date.sql`
   - Cole no editor SQL
   - Clique em "Run" para executar

4. **Verifique o Resultado**
   - O script irá mostrar mensagens de sucesso
   - Verifique se todas as colunas foram criadas corretamente

## Colunas que Serão Adicionadas

- `end_date` (DATE) - Data limite para jogos recorrentes
- `start_time` (TIME) - Horário de início (se não existir)
- `end_time` (TIME) - Horário de término (se não existir)

## Verificação

Após executar a migração, você pode verificar se as colunas foram criadas executando:

```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'games'
ORDER BY ordinal_position;
```

## Arquivos Relacionados

- `migration_add_end_date.sql` - Script principal de migração
- `add_end_date_column.sql` - Script simples para adicionar apenas end_date

## Notas

- A migração é segura e não afeta dados existentes
- As colunas são opcionais (nullable)
- O script verifica se as colunas já existem antes de tentar criá-las


