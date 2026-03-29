-- Migration: 03_skills
-- Description: Create skills catalog table
-- Issue: COO-1
-- Dependencies: 02_shared_functions.sql

-- ============================================
-- SKILLS (catalogo global)
-- ============================================
CREATE TABLE IF NOT EXISTS public.skills (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    normalized_name text NOT NULL UNIQUE,
    display_name   text NOT NULL,
    category        text,
    created_at      timestamptz DEFAULT now(),
    updated_at     timestamptz DEFAULT now()
);

ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;

-- RLS: everyone can read, only service role can write
CREATE POLICY "skills_select_all"
    ON public.skills FOR SELECT
    USING (true);

CREATE POLICY "skills_insert_service_role"
    ON public.skills FOR INSERT
    WITH CHECK (
        (select auth.role()) = 'service_role'
    );

CREATE POLICY "skills_update_service_role"
    ON public.skills FOR UPDATE
    USING (
        (select auth.role()) = 'service_role'
    );

CREATE POLICY "skills_delete_service_role"
    ON public.skills FOR DELETE
    USING (
        (select auth.role()) = 'service_role'
    );

-- Indexes
CREATE INDEX IF NOT EXISTS idx_skills_normalized_name ON public.skills(normalized_name);
CREATE INDEX IF NOT EXISTS idx_skills_category ON public.skills(category);

-- Trigger for updated_at
CREATE TRIGGER update_skills_updated_at
    BEFORE UPDATE ON public.skills
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
