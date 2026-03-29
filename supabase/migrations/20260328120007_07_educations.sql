-- Migration: 07_educations
-- Description: Create educations table
-- Issue: COO-1
-- Dependencies: 05_candidate_profiles.sql, 02_shared_functions.sql

-- ============================================
-- EDUCATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.educations (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    candidate_profile_id uuid NOT NULL REFERENCES public.candidate_profiles(id) ON DELETE CASCADE,
    institution     text NOT NULL,
    degree          text NOT NULL,
    field_of_study  text,
    start_date      date,
    end_date        date,
    grade           text,
    description     text,
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now()
);

ALTER TABLE public.educations ENABLE ROW LEVEL SECURITY;

-- RLS: owner sees all, public can see from public profiles
CREATE POLICY "educations_select"
    ON public.educations FOR SELECT
    USING (
        user_id = auth.uid() OR
        candidate_profile_id IN (
            SELECT id FROM public.candidate_profiles WHERE is_public = true
        )
    );

CREATE POLICY "educations_insert_owner"
    ON public.educations FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "educations_update_owner"
    ON public.educations FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "educations_delete_owner"
    ON public.educations FOR DELETE
    USING (user_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_educations_user_id ON public.educations(user_id);
CREATE INDEX IF NOT EXISTS idx_educations_candidate_profile_id ON public.educations(candidate_profile_id);
CREATE INDEX IF NOT EXISTS idx_educations_institution ON public.educations(institution);

-- Trigger for updated_at
CREATE TRIGGER update_educations_updated_at
    BEFORE UPDATE ON public.educations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
