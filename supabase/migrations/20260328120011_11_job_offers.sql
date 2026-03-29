-- Migration: 11_job_offers
-- Description: Create job_offers table with pgvector embedding
-- Issue: COO-1
-- Dependencies: 01_extensions.sql, 02_shared_functions.sql

-- ============================================
-- JOB_OFFERS
-- ============================================
CREATE TABLE IF NOT EXISTS public.job_offers (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title           text NOT NULL,
    company         text NOT NULL,
    location        text,
    location_type   text CHECK (location_type IN ('onsite', 'remote', 'hybrid')),
    employment_type text CHECK (employment_type IN ('full-time', 'part-time', 'contract', 'internship', 'freelance')),
    experience_level text CHECK (experience_level IN ('entry', 'mid', 'senior', 'lead', 'executive')),
    salary_min      integer,
    salary_max      integer,
    salary_currency text DEFAULT 'EUR',
    description     text NOT NULL,
    requirements    text,
    benefits        text,
    status          text CHECK (status IN ('draft', 'active', 'closed', 'archived')) DEFAULT 'draft',
    embedding       vector(1536),
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now()
);

ALTER TABLE public.job_offers ENABLE ROW LEVEL SECURITY;

-- RLS: all users can see active offers, owner sees all
CREATE POLICY "job_offers_select_all_active"
    ON public.job_offers FOR SELECT
    USING (
        user_id = auth.uid() OR status = 'active'
    );

CREATE POLICY "job_offers_insert_owner"
    ON public.job_offers FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "job_offers_update_owner"
    ON public.job_offers FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "job_offers_delete_owner"
    ON public.job_offers FOR DELETE
    USING (user_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_job_offers_user_id ON public.job_offers(user_id);
CREATE INDEX IF NOT EXISTS idx_job_offers_status ON public.job_offers(status);
CREATE INDEX IF NOT EXISTS idx_job_offers_company ON public.job_offers(company);
CREATE INDEX IF NOT EXISTS idx_job_offers_location ON public.job_offers(location);
CREATE INDEX IF NOT EXISTS idx_job_offers_experience_level ON public.job_offers(experience_level);
CREATE INDEX IF NOT EXISTS idx_job_offers_employment_type ON public.job_offers(employment_type);
CREATE INDEX IF NOT EXISTS idx_job_offers_status_active ON public.job_offers(status) WHERE status = 'active';

-- Vector similarity index (cosine distance for pgvector)
CREATE INDEX IF NOT EXISTS idx_job_offers_embedding_cosine
    ON public.job_offers
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

-- Trigger for updated_at
CREATE TRIGGER update_job_offers_updated_at
    BEFORE UPDATE ON public.job_offers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
