-- Migration: 10_certifications
-- Description: Create certifications table
-- Issue: COO-1
-- Dependencies: 05_candidate_profiles.sql, 02_shared_functions.sql

-- ============================================
-- CERTIFICATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.certifications (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    candidate_profile_id uuid NOT NULL REFERENCES public.candidate_profiles(id) ON DELETE CASCADE,
    name            text NOT NULL,
    issuing_organization text NOT NULL,
    issue_date      date,
    expiry_date     date,
    credential_id   text,
    credential_url  text,
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now()
);

ALTER TABLE public.certifications ENABLE ROW LEVEL SECURITY;

-- RLS: owner sees all, public can see from public profiles
CREATE POLICY "certifications_select"
    ON public.certifications FOR SELECT
    USING (
        user_id = auth.uid() OR
        candidate_profile_id IN (
            SELECT id FROM public.candidate_profiles WHERE is_public = true
        )
    );

CREATE POLICY "certifications_insert_owner"
    ON public.certifications FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "certifications_update_owner"
    ON public.certifications FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "certifications_delete_owner"
    ON public.certifications FOR DELETE
    USING (user_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_certifications_user_id ON public.certifications(user_id);
CREATE INDEX IF NOT EXISTS idx_certifications_candidate_profile_id ON public.certifications(candidate_profile_id);
CREATE INDEX IF NOT EXISTS idx_certifications_name ON public.certifications(name);

-- Trigger for updated_at
CREATE TRIGGER update_certifications_updated_at
    BEFORE UPDATE ON public.certifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
