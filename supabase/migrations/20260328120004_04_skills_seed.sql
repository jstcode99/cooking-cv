-- Migration: 04_skills_seed
-- Description: Seed skills catalog with initial data
-- Issue: COO-1
-- Dependencies: 03_skills.sql

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
