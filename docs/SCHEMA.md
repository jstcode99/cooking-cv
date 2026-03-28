# Schema Documentation - COO-1

## Overview

This document describes the database schema implemented in the `create-simplified-schema` migration.

## Tables

### 1. skills (Catálogo Global)
Almacena el catálogo global de habilidades/técnicas.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, DEFAULT gen_random_uuid() | Identificador único |
| normalized_name | text | NOT NULL, UNIQUE | Nombre normalizado (lowercase, sin espacios) |
| display_name | text | NOT NULL | Nombre para mostrar |
| category | text | | Categoría (programming_language, frontend, backend, etc.) |
| created_at | timestamptz | DEFAULT now() | Fecha de creación |
| updated_at | timestamptz | DEFAULT now() | Fecha de última modificación |

**Índices:**
- `idx_skills_normalized_name` ON normalized_name
- `idx_skills_category` ON category

**RLS:**
- SELECT: Todos pueden leer
- INSERT/UPDATE/DELETE: Solo service_role

### 2. candidate_profiles
Perfil público del candidato.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Identificador único |
| user_id | uuid | NOT NULL, UNIQUE, FK auth.users(id) | Usuario propietario |
| full_name | text | NOT NULL | Nombre completo |
| title | text | | Título profesional |
| summary | text | | Resumen del perfil |
| phone | text | | Teléfono de contacto |
| location | text | | Ubicación |
| linkedin_url | text | | URL de LinkedIn |
| github_url | text | | URL de GitHub |
| portfolio_url | text | | URL del portafolio |
| is_public | boolean | DEFAULT false | Perfil público |
| created_at | timestamptz | DEFAULT now() | Fecha de creación |
| updated_at | timestamptz | DEFAULT now() | Fecha de última modificación |

**Índices:**
- `idx_candidate_profiles_user_id` ON user_id
- `idx_candidate_profiles_is_public` ON is_public (WHERE is_public = true)

**RLS:**
- SELECT: Dueño o is_public = true
- INSERT/UPDATE/DELETE: Solo dueño

### 3. experiences
Experiencia laboral del candidato.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Identificador único |
| user_id | uuid | NOT NULL, FK auth.users(id) | Usuario propietario |
| candidate_profile_id | uuid | NOT NULL, FK candidate_profiles(id) | Perfil asociado |
| company_name | text | NOT NULL | Nombre de la empresa |
| job_title | text | NOT NULL | Puesto de trabajo |
| location | text | | Ubicación |
| location_type | text | CHECK (onsite, remote, hybrid) | Tipo de ubicación |
| start_date | date | NOT NULL | Fecha de inicio |
| end_date | date | | Fecha de fin |
| is_current | boolean | DEFAULT false | Trabajo actual |
| description | text | | Descripción del puesto |
| created_at | timestamptz | DEFAULT now() | Fecha de creación |
| updated_at | timestamptz | DEFAULT now() | Fecha de última modificación |

**Índices:**
- `idx_experiences_user_id` ON user_id
- `idx_experiences_candidate_profile_id` ON candidate_profile_id
- `idx_experiences_company_name` ON company_name
- `idx_experiences_start_date` ON start_date DESC

**RLS:**
- SELECT: Dueño o perfil público
- INSERT/UPDATE/DELETE: Solo dueño

### 4. educations
Formación académica del candidato.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Identificador único |
| user_id | uuid | NOT NULL, FK auth.users(id) | Usuario propietario |
| candidate_profile_id | uuid | NOT NULL, FK candidate_profiles(id) | Perfil asociado |
| institution | text | NOT NULL | Institución educativa |
| degree | text | NOT NULL | Título obtenido |
| field_of_study | text | | Campo de estudio |
| start_date | date | | Fecha de inicio |
| end_date | date | | Fecha de fin |
| grade | text | | Calificación/nota |
| description | text | | Descripción adicional |
| created_at | timestamptz | DEFAULT now() | Fecha de creación |
| updated_at | timestamptz | DEFAULT now() | Fecha de última modificación |

**Índices:**
- `idx_educations_user_id` ON user_id
- `idx_educations_candidate_profile_id` ON candidate_profile_id
- `idx_educations_institution` ON institution

**RLS:**
- SELECT: Dueño o perfil público
- INSERT/UPDATE/DELETE: Solo dueño

### 5. user_skills
Habilidades del usuario con nivel de proficiencia.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Identificador único |
| user_id | uuid | NOT NULL, FK auth.users(id) | Usuario propietario |
| skill_id | uuid | NOT NULL, FK skills(id) | Habilidad del catálogo |
| proficiency_level | integer | CHECK (1-5) | Nivel de proficiencia |
| years_experience | integer | | Años de experiencia |
| created_at | timestamptz | DEFAULT now() | Fecha de creación |
| updated_at | timestamptz | DEFAULT now() | Fecha de última modificación |

**Constraints:**
- UNIQUE(user_id, skill_id)

**Índices:**
- `idx_user_skills_user_id` ON user_id
- `idx_user_skills_skill_id` ON skill_id
- `idx_user_skills_proficiency` ON proficiency_level DESC

**RLS:**
- SELECT: Dueño o usuario con perfil público
- INSERT/UPDATE/DELETE: Solo dueño

### 6. languages
Idiomas del candidato.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Identificador único |
| user_id | uuid | NOT NULL, FK auth.users(id) | Usuario propietario |
| candidate_profile_id | uuid | NOT NULL, FK candidate_profiles(id) | Perfil asociado |
| language | text | NOT NULL | Idioma |
| proficiency | text | CHECK (native, fluent, advanced, intermediate, basic) | Nivel de proficiencia |
| created_at | timestamptz | DEFAULT now() | Fecha de creación |
| updated_at | timestamptz | DEFAULT now() | Fecha de última modificación |

**Índices:**
- `idx_languages_user_id` ON user_id
- `idx_languages_candidate_profile_id` ON candidate_profile_id
- `idx_languages_language` ON language

**RLS:**
- SELECT: Dueño o perfil público
- INSERT/UPDATE/DELETE: Solo dueño

### 7. certifications
Certificaciones del candidato.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Identificador único |
| user_id | uuid | NOT NULL, FK auth.users(id) | Usuario propietario |
| candidate_profile_id | uuid | NOT NULL, FK candidate_profiles(id) | Perfil asociado |
| name | text | NOT NULL | Nombre de la certificación |
| issuing_organization | text | NOT NULL | Organización emissora |
| issue_date | date | | Fecha de emisión |
| expiry_date | date | | Fecha de expiración |
| credential_id | text | | ID de la credencial |
| credential_url | text | | URL de la credencial |
| created_at | timestamptz | DEFAULT now() | Fecha de creación |
| updated_at | timestamptz | DEFAULT now() | Fecha de última modificación |

**Índices:**
- `idx_certifications_user_id` ON user_id
- `idx_certifications_candidate_profile_id` ON candidate_profile_id
- `idx_certifications_name` ON name

**RLS:**
- SELECT: Dueño o perfil público
- INSERT/UPDATE/DELETE: Solo dueño

### 8. job_offers
Ofertas de trabajo con embedding para búsqueda vectorial.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Identificador único |
| user_id | uuid | NOT NULL, FK auth.users(id) | Usuario creador |
| title | text | NOT NULL | Título del puesto |
| company | text | NOT NULL | Empresa |
| location | text | | Ubicación |
| location_type | text | CHECK (onsite, remote, hybrid) | Tipo de ubicación |
| employment_type | text | CHECK (full-time, part-time, contract, internship, freelance) | Tipo de empleo |
| experience_level | text | CHECK (entry, mid, senior, lead, executive) | Nivel de experiencia |
| salary_min | integer | | Salario mínimo |
| salary_max | integer | | Salario máximo |
| salary_currency | text | DEFAULT 'EUR' | Moneda |
| description | text | NOT NULL | Descripción del puesto |
| requirements | text | | Requisitos |
| benefits | text | | Beneficios |
| status | text | CHECK (draft, active, closed, archived) DEFAULT 'draft' | Estado |
| embedding | vector(1536) | | Embedding para pgvector |
| created_at | timestamptz | DEFAULT now() | Fecha de creación |
| updated_at | timestamptz | DEFAULT now() | Fecha de última modificación |

**Índices:**
- `idx_job_offers_user_id` ON user_id
- `idx_job_offers_status` ON status
- `idx_job_offers_company` ON company
- `idx_job_offers_location` ON location
- `idx_job_offers_experience_level` ON experience_level
- `idx_job_offers_employment_type` ON employment_type
- `idx_job_offers_status_active` ON status WHERE status = 'active'
- `idx_job_offers_embedding_cosine` IVFFLAT para búsqueda vectorial

**RLS:**
- SELECT: Dueño o status = 'active'
- INSERT/UPDATE/DELETE: Solo dueño

### 9. candidate_profile_history
Historial de cambios del perfil del candidato.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Identificador único |
| candidate_profile_id | uuid | NOT NULL, FK candidate_profiles(id) | Perfil modificado |
| user_id | uuid | NOT NULL, FK auth.users(id) | Usuario propietario |
| change_type | text | NOT NULL CHECK (created, updated, deleted) | Tipo de cambio |
| changed_fields | jsonb | | Campos modificados (old/new) |
| snapshot | jsonb | NOT NULL | Snapshot del registro |
| created_at | timestamptz | DEFAULT now() | Fecha del cambio |

**Índices:**
- `idx_candidate_profile_history_profile_id` ON candidate_profile_id
- `idx_candidate_profile_history_user_id` ON user_id
- `idx_candidate_profile_history_created_at` ON created_at DESC
- `idx_candidate_profile_history_change_type` ON change_type

**RLS:**
- SELECT: Solo dueño
- INSERT: Solo service_role o owner
- UPDATE/DELETE: Denegado

## Triggers

### updated_at automático
Todas las tablas (excepto candidate_profile_history) tienen un trigger `update_<table>_updated_at` que actualiza automáticamente el campo `updated_at` en cada UPDATE.

### Logging de candidate_profiles
Trigger `candidate_profile_history_trigger` que registra automáticamente:
- INSERT: Crea registro con change_type = 'created'
- UPDATE: Crea registro con change_type = 'updated' y changed_fields con diff
- DELETE: Crea registro con change_type = 'deleted'

## Extensiones

- **vector**: Extensión pgvector para almacenamiento de embeddings (VECTOR(1536))

## Catálogo de Skills (Seed)

El catálogo inicial incluye 57 habilidades en las categorías:
- Programming Languages (13): javascript, typescript, python, java, csharp, cpp, go, rust, ruby, php, swift, kotlin
- Frontend (7): react, nextjs, vue, angular, svelte, html, css, tailwind, sass
- Backend (7): nodejs, express, django, flask, spring, rails, aspnet
- Databases (6): postgresql, mysql, mongodb, redis, sqlite, oracle
- Cloud & DevOps (11): aws, gcp, azure, docker, kubernetes, terraform, jenkins, gitlab, github_actions
- Tools (4): git, linux, bash, vim
- Soft Skills (5): leadership, communication, teamwork, problem_solving, analytical
