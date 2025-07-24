-- ==============================================================================
-- DATABASE CLEANUP SCRIPT - PostgreSQL 16 Compatible
-- This script removes all objects created by the setup script.
-- ==============================================================================
-- Connect to your PostgreSQL 16 instance and run this script to clean up.

-- ------------------------------------------------------------------------------
-- 1. DROP TABLES
-- ------------------------------------------------------------------------------
-- Dropping tables with the CASCADE option automatically removes dependent objects
-- such as foreign key constraints, triggers, and the sequences from SERIAL columns.
-- We drop tables that are referenced by others first to be explicit, though
-- CASCADE handles this automatically.

DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;

-- ------------------------------------------------------------------------------
-- 2. DROP FUNCTION
-- ------------------------------------------------------------------------------
-- The triggers were removed when the tables were dropped, but the function
-- they called still exists and must be dropped separately.

DROP FUNCTION IF EXISTS update_updated_at_column();

-- ------------------------------------------------------------------------------
-- 3. DROP PUBLICATION
-- ------------------------------------------------------------------------------
-- Drop the replication publication created for Datastream.

DROP PUBLICATION IF EXISTS datastream_publication_dev;

-- ------------------------------------------------------------------------------
-- 4. REVOKE PERMISSIONS & ROLES
-- ------------------------------------------------------------------------------
-- This section revokes all permissions granted to 'datastream_user'.
-- Note: This script does NOT drop the 'datastream_user' role itself.

-- Revoke default privileges for any future tables in the schema.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM datastream_user;

-- Revoke permissions on the schemas.
REVOKE USAGE ON SCHEMA public FROM datastream_user;
REVOKE USAGE ON SCHEMA information_schema FROM datastream_user;

-- Remove the REPLICATION attribute from the user.
-- NOTE: You must have superuser privileges to execute this command.
ALTER USER datastream_user WITH NOREPLICATION;

-- ==============================================================================
-- CLEANUP COMPLETE
-- ==============================================================================