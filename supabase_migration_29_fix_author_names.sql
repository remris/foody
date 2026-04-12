-- Einmaliges Update: author_name in allen Community-Tabellen
-- aus user_profiles.display_name aktualisieren.
-- Behebt das Problem dass alte Posts/Shares den Email-Prefix statt den
-- aktuellen Profil-Namen anzeigen.

-- Community Posts
UPDATE public.community_posts cp
SET author_name = up.display_name
FROM public.user_profiles up
WHERE cp.user_id = up.id
  AND up.display_name IS NOT NULL
  AND up.display_name != ''
  AND (cp.author_name IS NULL OR cp.author_name != up.display_name);

-- Community Shares
UPDATE public.community_shares cs
SET offered_by_name = up.display_name
FROM public.user_profiles up
WHERE cs.offered_by = up.id
  AND up.display_name IS NOT NULL
  AND up.display_name != ''
  AND (cs.offered_by_name IS NULL OR cs.offered_by_name != up.display_name);

-- Community Recipes
UPDATE public.community_recipes cr
SET author_name = up.display_name
FROM public.user_profiles up
WHERE cr.user_id = up.id
  AND up.display_name IS NOT NULL
  AND up.display_name != ''
  AND (cr.author_name IS NULL OR cr.author_name != up.display_name);

-- Community Meal Plans
UPDATE public.community_meal_plans cmp
SET author_name = up.display_name
FROM public.user_profiles up
WHERE cmp.user_id = up.id
  AND up.display_name IS NOT NULL
  AND up.display_name != ''
  AND (cmp.author_name IS NULL OR cmp.author_name != up.display_name);

-- Social Posts
UPDATE public.social_posts sp
SET author_name = up.display_name
FROM public.user_profiles up
WHERE sp.user_id = up.id
  AND up.display_name IS NOT NULL
  AND up.display_name != ''
  AND (sp.author_name IS NULL OR sp.author_name != up.display_name);

-- Social Post Comments
UPDATE public.social_post_comments spc
SET author_name = up.display_name
FROM public.user_profiles up
WHERE spc.user_id = up.id
  AND up.display_name IS NOT NULL
  AND up.display_name != ''
  AND (spc.author_name IS NULL OR spc.author_name != up.display_name);

