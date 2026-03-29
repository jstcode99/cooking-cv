-- Migration: 06_experiences
-- Description: Create experiences table
-- Issue: COO-1
-- Dependencies: 05_candidate_profiles.sql, 02_shared_functions.sql

-- ============================================
-- EXPERIENCES
-- ============================================
CREATE TABLE IF NOT EXISTS public.experiences (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    candidate_profile_id uuid NOT NULL REFERENCES public.candidate_profiles(id) ON DELETE CASCADE,
    company_name    text NOT NULL,
    job_title      text NOT NULL,
    location       text,
    location_type   text CHECK (location_type IN ('onsite', 'remote', 'hybrid')),
    start_date      date NOT NULL,
    end_date        date,
    is_current      boolean DEFAULT false,
    description     text,
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now()
);

ALTER TABLE public.experiences ENABLE ROW LEVEL SECURITY;

-- RLS: owner sees all, public can see experiences from public profiles
CREATE POLICY "experiences_select"
    ON public.experiences FOR SELECT
    USING (
        user_id = auth.uid() OR
        candidate_profile_id IN (
            SELECT id FROM public.candidate_profiles WHERE is_public = true
        )
    );

CREATE POLICY "experiences_insert_owner"
    ON public.experiences FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "experiences_update_owner"
    ON public.experiences FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "experiences_delete_owner"
    ON public.experiences FOR DELETE
    USING (user_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_experiences_user_id ON public.experiences(user_id);
CREATE INDEX IF NOT EXISTS idx_experiences_candidate_profile_id ON public.experiences(candidate_profile_id);
CREATE INDEX IF NOT EXISTS idx_experiences_company_name ON public.experiences(company_name);
CREATE INDEX IF NOT EXISTS idx_experiences_start_date ON public.experiences(start_date DESC);

-- Trigger for updated_at
CREATE TRIGGER update_experiences_updated_at
    BEFORE UPDATE ON public.experiences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
