-- Migration: 08_user_skills
-- Description: Create user_skills table (junction table between users and skills)
-- Issue: COO-1
-- Dependencies: 03_skills.sql, 02_shared_functions.sql

-- ============================================
-- USER_SKILLS
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_skills (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    skill_id        uuid NOT NULL REFERENCES public.skills(id) ON DELETE CASCADE,
    proficiency_level integer CHECK (proficiency_level >= 1 AND proficiency_level <= 5),
    years_experience integer,
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now(),
    UNIQUE(user_id, skill_id)
);

ALTER TABLE public.user_skills ENABLE ROW LEVEL SECURITY;

-- RLS: owner sees all, public can see from public profiles
CREATE POLICY "user_skills_select"
    ON public.user_skills FOR SELECT
    USING (
        user_id = auth.uid() OR
        user_id IN (
            SELECT user_id FROM public.candidate_profiles WHERE is_public = true
        )
    );

CREATE POLICY "user_skills_insert_owner"
    ON public.user_skills FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_skills_update_owner"
    ON public.user_skills FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "user_skills_delete_owner"
    ON public.user_skills FOR DELETE
    USING (user_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_skills_user_id ON public.user_skills(user_id);
CREATE INDEX IF NOT EXISTS idx_user_skills_skill_id ON public.user_skills(skill_id);
CREATE INDEX IF NOT EXISTS idx_user_skills_proficiency ON public.user_skills(proficiency_level DESC);

-- Trigger for updated_at
CREATE TRIGGER update_user_skills_updated_at
    BEFORE UPDATE ON public.user_skills
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
