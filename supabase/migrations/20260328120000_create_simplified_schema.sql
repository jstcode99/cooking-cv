-- Migration: create-simplified-schema
-- Description: Create complete schema with 10 tables, RLS, triggers and indexes
-- Issue: COO-1

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================
-- 1. SKILLS (catalogo global)
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
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_skills_updated_at
    BEFORE UPDATE ON public.skills
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 2. CANDIDATE_PROFILES
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

-- ============================================
-- 3. EXPERIENCES
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

-- ============================================
-- 4. EDUCATIONS
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

-- ============================================
-- 5. USER_SKILLS
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

-- ============================================
-- 6. LANGUAGES
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

-- ============================================
-- 7. CERTIFICATIONS
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

-- ============================================
-- 8. JOB_OFFERS
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

-- ============================================
-- 9. CANDIDATE_PROFILE_HISTORY
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

-- ============================================
-- 10. TRIGGER FOR HISTORY LOGGING
-- ============================================
CREATE OR REPLACE FUNCTION log_candidate_profile_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.candidate_profile_history (candidate_profile_id, user_id, change_type, snapshot)
        VALUES (NEW.id, NEW.user_id, 'created', to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.candidate_profile_history (candidate_profile_id, user_id, change_type, changed_fields, snapshot)
        VALUES (NEW.id, NEW.user_id, 'updated', 
            jsonb_build_object(
                'old', to_jsonb(OLD) - 'updated_at' - 'created_at',
                'new', to_jsonb(NEW) - 'updated_at' - 'created_at'
            ),
            to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.candidate_profile_history (candidate_profile_id, user_id, change_type, snapshot)
        VALUES (OLD.id, OLD.user_id, 'deleted', to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for candidate profile history
CREATE TRIGGER candidate_profile_history_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.candidate_profiles
    FOR EACH ROW
    EXECUTE FUNCTION log_candidate_profile_changes();

-- ============================================
-- SEED SKILLS CATALOG
-- ============================================
INSERT INTO public.skills (normalized_name, display_name, category) VALUES
-- Programming Languages
('javascript', 'JavaScript', 'programming_language'),
('typescript', 'TypeScript', 'programming_language'),
('python', 'Python', 'programming_language'),
('java', 'Java', 'programming_language'),
('csharp', 'C#', 'programming_language'),
('cpp', 'C++', 'programming_language'),
('go', 'Go', 'programming_language'),
('rust', 'Rust', 'programming_language'),
('ruby', 'Ruby', 'programming_language'),
('php', 'PHP', 'programming_language'),
('swift', 'Swift', 'programming_language'),
('kotlin', 'Kotlin', 'programming_language'),
-- Frontend
('react', 'React', 'frontend'),
('nextjs', 'Next.js', 'frontend'),
('vue', 'Vue.js', 'frontend'),
('angular', 'Angular', 'frontend'),
('svelte', 'Svelte', 'frontend'),
('html', 'HTML', 'frontend'),
('css', 'CSS', 'frontend'),
('tailwind', 'Tailwind CSS', 'frontend'),
('sass', 'SASS/SCSS', 'frontend'),
-- Backend
('nodejs', 'Node.js', 'backend'),
('express', 'Express.js', 'backend'),
('django', 'Django', 'backend'),
('flask', 'Flask', 'backend'),
('spring', 'Spring Boot', 'backend'),
('rails', 'Ruby on Rails', 'backend'),
('aspnet', 'ASP.NET', 'backend'),
-- Databases
('postgresql', 'PostgreSQL', 'database'),
('mysql', 'MySQL', 'database'),
('mongodb', 'MongoDB', 'database'),
('redis', 'Redis', 'database'),
('sqlite', 'SQLite', 'database'),
('oracle', 'Oracle', 'database'),
-- Cloud & DevOps
('aws', 'AWS', 'cloud'),
('gcp', 'Google Cloud', 'cloud'),
('azure', 'Azure', 'cloud'),
('docker', 'Docker', 'devops'),
('kubernetes', 'Kubernetes', 'devops'),
('terraform', 'Terraform', 'devops'),
('jenkins', 'Jenkins', 'devops'),
('gitlab', 'GitLab CI/CD', 'devops'),
('github_actions', 'GitHub Actions', 'devops'),
-- Tools
('git', 'Git', 'tool'),
('linux', 'Linux', 'tool'),
('bash', 'Bash/Shell', 'tool'),
('vim', 'Vim', 'tool'),
-- Soft Skills
('leadership', 'Leadership', 'soft_skill'),
('communication', 'Communication', 'soft_skill'),
('teamwork', 'Teamwork', 'soft_skill'),
('problem_solving', 'Problem Solving', 'soft_skill'),
('analytical', 'Analytical Thinking', 'soft_skill')
ON CONFLICT (normalized_name) DO NOTHING;
