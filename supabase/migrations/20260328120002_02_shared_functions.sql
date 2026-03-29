-- Migration: 02_shared_functions
-- Description: Create shared utility functions
-- Issue: COO-1
-- Dependencies: 01_extensions.sql

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
