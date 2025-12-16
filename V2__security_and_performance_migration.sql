-- V2 MIGRATION: Security & Performance Overhaul
-- This script safely migrates the database schema from V1 to V2 without data loss.

-- STEP 1: Create the new 'user_private_data' table.
-- This table will securely store sensitive user information.
CREATE TABLE IF NOT EXISTS public.user_private_data (
    id uuid NOT NULL PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    phone text NULL
);
COMMENT ON TABLE public.user_private_data IS 'Stores private user data, accessible only by the user.';

-- STEP 2: Copy existing phone numbers to the new table.
-- This is a critical data preservation step. It checks if the 'phone' column
-- exists in the 'users' table before attempting the copy.
DO $$
BEGIN
    IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='phone') THEN
        INSERT INTO public.user_private_data (id, phone)
        SELECT id, phone FROM public.users
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- STEP 3: Remove the 'phone' column from the public 'users' table.
-- This completes the separation of public and private data.
DO $$
BEGIN
    IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='phone') THEN
        ALTER TABLE public.users DROP COLUMN phone;
    END IF;
END $$;

-- STEP 4: Drop the old, redundant user creation trigger and function.
-- This prevents duplicate record creation and ensures the new, unified trigger handles user setup.
DROP TRIGGER IF EXISTS on_new_user_create_stats ON auth.users;
DROP FUNCTION IF EXISTS public.create_user_stats_on_signup();

-- STEP 5: Apply the new, stricter RLS policies for the private data table.
ALTER TABLE public.user_private_data ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_private_data_all_own" ON public.user_private_data FOR ALL
    USING (auth.uid() = id);

-- MIGRATION COMPLETE --
