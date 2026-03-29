-- Migration: 12_candidate_profile_history
-- Description: Create candidate_profile_history table
-- Issue: COO-1
-- Dependencies: 05_candidate_profiles.sql

-- ============================================
-- CANDIDATE_PROFILE_HISTORY
-- ============================================
CREATE TABLE IF NOT EXISTS public.candidate_profile_history (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_profile_id uuid NOT NULL REFERENCES public.candidate_profiles(id) ON DELETE CASCADE,
    user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    change_type     text NOT NULL CHECK (change_type IN ('created', 'updated', 'deleted')),
    changed_fields  jsonb,
    snapshot        jsonb NOT NULL,
    created_at      timestamptz DEFAULT now()
);

ALTER TABLE public.candidate_profile_history ENABLE ROW LEVEL SECURITY;

-- RLS: only owner can read
CREATE POLICY "candidate_profile_history_select_owner"
    ON public.candidate_profile_history FOR SELECT
    USING (user_id = auth.uid());

-- Only system/trigger can insert
CREATE POLICY "candidate_profile_history_insert_system"
    ON public.candidate_profile_history FOR INSERT
    WITH CHECK (
        (select auth.role()) = 'service_role' OR user_id = auth.uid()
    );

-- No update or delete for history
CREATE POLICY "candidate_profile_history_no_update"
    ON public.candidate_profile_history FOR UPDATE
    USING (false);

CREATE POLICY "candidate_profile_history_no_delete"
    ON public.candidate_profile_history FOR DELETE
    USING (false);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_candidate_profile_history_profile_id ON public.candidate_profile_history(candidate_profile_id);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_history_user_id ON public.candidate_profile_history(user_id);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_history_created_at ON public.candidate_profile_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_history_change_type ON public.candidate_profile_history(change_type);
