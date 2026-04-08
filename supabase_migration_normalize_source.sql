-- Migration: 'manual' source → 'own' normalisieren
-- Betrifft: saved_recipes Einträge die vor der source-Umbenennung erstellt wurden

UPDATE public.saved_recipes
SET
  source = 'own',
  recipe_json = recipe_json || '{"source": "own"}'
WHERE source = 'manual';

-- Einträge ohne source (NULL oder leer) → 'ai' als Default
UPDATE public.saved_recipes
SET
  source = 'ai',
  recipe_json = recipe_json || '{"source": "ai"}'
WHERE source IS NULL OR source = '';

-- Überprüfung
SELECT source, COUNT(*) as anzahl
FROM public.saved_recipes
GROUP BY source
ORDER BY anzahl DESC;

