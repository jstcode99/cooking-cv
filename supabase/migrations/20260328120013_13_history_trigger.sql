-- Migration: 13_history_trigger
-- Description: Create trigger function and trigger for candidate profile history logging
-- Issue: COO-1
-- Dependencies: 12_candidate_profile_history.sql

-- ============================================
-- TRIGGER FOR HISTORY LOGGING
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
