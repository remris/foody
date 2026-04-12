-- ============================================================
-- Seed: Test-Community mit Testdaten
-- Admin: 71808529-2f92-4772-bacd-235c8fa37ea5
-- ============================================================

-- FK vor dem Block droppen (DDL darf nicht in PL/pgSQL DO-Block)
ALTER TABLE public.community_shares
  DROP CONSTRAINT IF EXISTS community_shares_offered_by_fkey;
ALTER TABLE public.community_shares
  DROP CONSTRAINT IF EXISTS community_shares_community_id_fkey;

DO $$
DECLARE
  v_community_id  UUID := gen_random_uuid();
  v_admin_id      UUID := '71808529-2f92-4772-bacd-235c8fa37ea5';
BEGIN

  -- ── 1. Community erstellen ───────────────────────────────────────────────
  INSERT INTO public.communities (id, name, description, plz, city, invite_code, admin_id, max_members, is_public)
  VALUES (
    v_community_id,
    'Nachbarn Schillerstraße',
    'Unsere kleine Nachbarschafts-Community zum Tauschen von Lebensmitteln, Rezepten und Resten. Jeder ist willkommen!',
    '10115',
    'Berlin',
    'SCHIL1',
    v_admin_id,
    50,
    true
  );

  -- ── 2. Mitglieder ────────────────────────────────────────────────────────
  INSERT INTO public.community_members (community_id, user_id, display_name, status, joined_at)
  VALUES (v_community_id, v_admin_id, 'Admin (Du)', 'active', now() - interval '10 days');

  -- ── 3. Posts ─────────────────────────────────────────────────────────────
  INSERT INTO public.community_posts (community_id, user_id, content, author_name, created_at)
  VALUES
    (v_community_id, v_admin_id,
     'Willkommen in unserer Community! 🎉 Hier können wir Reste teilen, Rezepte empfehlen und uns gegenseitig beim Kochen helfen. Freue mich auf euch!',
     'Admin (Du)', now() - interval '9 days'),
    (v_community_id, v_admin_id,
     'Ich habe heute frisches Sauerteigbrot gebacken und noch einen ganzen Laib übrig. Wer Interesse hat einfach melden – kostenlos natürlich! 🍞',
     'Admin (Du)', now() - interval '7 days'),
    (v_community_id, v_admin_id,
     'Rezeptidee der Woche: Übrig gebliebene Pasta lässt sich super als Frittata verwerten. Einfach Eier verquirlen, Pasta rein, Käse drüber und bei mittlerer Hitze stocken lassen. Schmeckt am nächsten Tag noch besser! 🍳',
     'Admin (Du)', now() - interval '5 days'),
    (v_community_id, v_admin_id,
     'Kleine Erinnerung: Wenn ihr Lebensmittel anbietet die bis zu einem bestimmten Datum weg müssen, bitte das Datum im Hinweis vermerken. Danke! 🙏',
     'Admin (Du)', now() - interval '3 days'),
    (v_community_id, v_admin_id,
     'Hat jemand eine gute Quelle für saisonales Gemüse hier in der Gegend? Der Markt samstags am Kollwitzplatz ist super, aber gibt es noch was in der Nähe? 🥕🥦',
     'Admin (Du)', now() - interval '2 days'),
    (v_community_id, v_admin_id,
     'Mein Apfelbaum trägt dieses Jahr wie verrückt 🍎 Ich werde in den nächsten Wochen regelmäßig Äpfel anbieten – einfach unter „Teilen" schauen!',
     'Admin (Du)', now() - interval '1 day'),
    (v_community_id, v_admin_id,
     'Guten Morgen zusammen! ☀️ Heute mache ich Gemüsesuppe auf Vorrat. Falls jemand eine Portion möchte – melde dich bis 17 Uhr, dann stelle ich sie vor die Tür.',
     'Admin (Du)', now() - interval '2 hours');

  -- ── 4. Eigene Shares ─────────────────────────────────────────────────────
  INSERT INTO public.community_shares (community_id, offered_by, offered_by_name, item_name, quantity, note, status, created_at)
  VALUES
    (v_community_id, v_admin_id, 'Admin (Du)',
     'Äpfel vom Baum', 'ca. 2 kg',
     'Bitte bis Freitag abholen, Hauseingang links klingeln',
     'available', now() - interval '1 day'),
    (v_community_id, v_admin_id, 'Admin (Du)',
     'Sauerteigbrot (halb)', '1 Laib',
     'Heute gebacken, noch frisch. Roggen-Weizen-Mischung.',
     'available', now() - interval '7 days'),
    (v_community_id, v_admin_id, 'Admin (Du)',
     'Basilikum-Pflanze', '1 Topf',
     'Zu groß für meine Fensterbank geworden – wer möchte sie haben?',
     'available', now() - interval '6 days');

  -- ── 5. Fremde Shares (FK ist draußen, keine UUID-Prüfung) ────────────────
  INSERT INTO public.community_shares (community_id, offered_by, offered_by_name, item_name, quantity, note, status, created_at)
  VALUES
    (v_community_id, 'bbbbbbbb-0000-0000-0000-000000000001', 'Maria S.',
     'Selbstgemachte Erdbeermarmelade', '3 Gläser',
     'Aus diesem Sommer, noch gut verschlossen.',
     'available', now() - interval '3 days'),
    (v_community_id, 'bbbbbbbb-0000-0000-0000-000000000002', 'Thomas K.',
     'Zucchini aus dem Garten', 'ca. 1,5 kg',
     'Dieses Jahr zu viel geerntet 😄',
     'available', now() - interval '4 days'),
    (v_community_id, 'bbbbbbbb-0000-0000-0000-000000000001', 'Maria S.',
     'Reste Gemüsesuppe', '3 Portionen',
     'Von heute Mittag, noch warm. Vegan 🌱',
     'available', now() - interval '2 hours'),
    (v_community_id, 'bbbbbbbb-0000-0000-0000-000000000003', 'Lukas W.',
     'Griechischer Joghurt', '400 g',
     'MHD morgen – noch einwandfrei, ich schaffe ihn nicht mehr',
     'available', now() - interval '5 hours');

  RAISE NOTICE '✅ Community erstellt! ID: %', v_community_id;
  RAISE NOTICE '   Einladungscode: SCHIL1 | Posts: 7 | Shares: 7';

END $$;

-- Beide FKs mit NOT VALID wieder hinzufügen (bestehende Zeilen werden nicht geprüft)
ALTER TABLE public.community_shares
  ADD CONSTRAINT community_shares_community_id_fkey
  FOREIGN KEY (community_id) REFERENCES public.communities(id) ON DELETE CASCADE
  NOT VALID;

ALTER TABLE public.community_shares
  ADD CONSTRAINT community_shares_offered_by_fkey
  FOREIGN KEY (offered_by) REFERENCES auth.users(id) ON DELETE CASCADE
  NOT VALID;
