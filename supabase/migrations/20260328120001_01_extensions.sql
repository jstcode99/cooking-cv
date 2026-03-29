-- Migration: 01_extensions
-- Description: Enable PostgreSQL extensions
-- Issue: COO-1
-- Dependencies: None

-- Enable pgvector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector;
