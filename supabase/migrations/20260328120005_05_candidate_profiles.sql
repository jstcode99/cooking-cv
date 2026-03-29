-- Migration: 05_candidate_profiles
-- Description: Create candidate profiles table
-- Issue: COO-1
-- Dependencies: 02_shared_functions.sql

-- ============================================
-- CANDIDATE_PROFILES
-- ============================================
CREATE TABLE IF NOT EXISTS public.candidate_profiles (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name       text NOT NULL,
    title           text,
    summary         text,
    phone           text,
    location        text,
    linkedin_url    text,
    github_url      text,
    portfolio_url   text,
    is_public       boolean DEFAULT false,
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now()
);

ALTER TABLE public.candidate_profiles ENABLE ROW LEVEL SECURITY;

-- RLS: owner can do everything, others can only see public profiles
CREATE POLICY "candidate_profiles_select_owner"
    ON public.candidate_profiles FOR SELECT
    USING (
        user_id = auth.uid() OR is_public = true
    );

CREATE POLICY "candidate_profiles_insert_owner"
    ON public.candidate_profiles FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "candidate_profiles_update_owner"
    ON public.candidate_profiles FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "candidate_profiles_delete_owner"
    ON public.candidate_profiles FOR DELETE
    USING (user_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_candidate_profiles_user_id ON public.candidate_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_candidate_profiles_is_public ON public.candidate_profiles(is_public) WHERE is_public = true;

-- Trigger for updated_at
CREATE TRIGGER update_candidate_profiles_updated_at
    BEFORE UPDATE ON public.candidate_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
