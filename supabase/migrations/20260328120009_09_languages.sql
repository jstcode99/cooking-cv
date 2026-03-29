-- Migration: 09_languages
-- Description: Create languages table
-- Issue: COO-1
-- Dependencies: 05_candidate_profiles.sql, 02_shared_functions.sql

-- ============================================
-- LANGUAGES
-- ============================================
CREATE TABLE IF NOT EXISTS public.languages (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    candidate_profile_id uuid NOT NULL REFERENCES public.candidate_profiles(id) ON DELETE CASCADE,
    language        text NOT NULL,
    proficiency     text CHECK (proficiency IN ('native', 'fluent', 'advanced', 'intermediate', 'basic')),
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now()
);

ALTER TABLE public.languages ENABLE ROW LEVEL SECURITY;

-- RLS: owner sees all, public can see from public profiles
CREATE POLICY "languages_select"
    ON public.languages FOR SELECT
    USING (
        user_id = auth.uid() OR
        candidate_profile_id IN (
            SELECT id FROM public.candidate_profiles WHERE is_public = true
        )
    );

CREATE POLICY "languages_insert_owner"
    ON public.languages FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "languages_update_owner"
    ON public.languages FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "languages_delete_owner"
    ON public.languages FOR DELETE
    USING (user_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_languages_user_id ON public.languages(user_id);
CREATE INDEX IF NOT EXISTS idx_languages_candidate_profile_id ON public.languages(candidate_profile_id);
CREATE INDEX IF NOT EXISTS idx_languages_language ON public.languages(language);

-- Trigger for updated_at
CREATE TRIGGER update_languages_updated_at
    BEFORE UPDATE ON public.languages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
