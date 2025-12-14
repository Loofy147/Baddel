-- Baddel - Supabase Database Setup SQL
-- Version: 1.0 (Beta)

-- This script contains the complete schema for the Baddel application.
-- Run this in your Supabase SQL Editor to set up the database.

-- ----------------------------------------------------------------
-- 1. TABLES
-- ----------------------------------------------------------------

-- public.users table
CREATE TABLE public.users (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id),
    phone text NULL,
    reputation_score integer DEFAULT 50 NOT NULL,
    badges text[] NULL
);
COMMENT ON TABLE public.users IS 'Stores public user profiles, linked to Supabase authentication.';

-- public.items table
CREATE TABLE public.items (
    id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
    owner_id uuid NOT NULL REFERENCES public.users(id),
    title text NOT NULL,
    price integer DEFAULT 0 NOT NULL,
    image_url text NOT NULL,
    accepts_swaps boolean DEFAULT false NOT NULL,
    is_cash_only boolean DEFAULT true NOT NULL,
    location geography(Point, 4326) NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE public.items IS 'Contains all items listed by users for sale or swap.';

-- public.offers table
CREATE TABLE public.offers (
    id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
    buyer_id uuid NOT NULL REFERENCES public.users(id),
    seller_id uuid NOT NULL REFERENCES public.users(id),
    target_item_id uuid NOT NULL REFERENCES public.items(id),
    offered_item_id uuid NULL REFERENCES public.items(id),
    cash_amount integer DEFAULT 0 NOT NULL,
    type text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE public.offers IS 'Manages all deal proposals (cash, swap, or hybrid).';

-- public.messages table
CREATE TABLE public.messages (
    id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
    offer_id uuid NOT NULL REFERENCES public.offers(id),
    sender_id uuid NOT NULL REFERENCES public.users(id),
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.messages IS 'Real-time chat for accepted deals.';

-- ----------------------------------------------------------------
-- 2. PostgreSQL Function for Geolocation Queries
-- ----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_items_nearby;

CREATE OR REPLACE FUNCTION get_items_nearby(
  lat float,
  lng float,
  radius_meters int DEFAULT 50000 -- Default 50km
)
RETURNS TABLE (
  id uuid,
  title text,
  price int,
  image_url text,
  accepts_swaps boolean,
  owner_id uuid,
  dist_meters float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    i.id,
    i.title,
    i.price,
    i.image_url,
    i.accepts_swaps,
    i.owner_id,
    st_distance(i.location, st_point(lng, lat)::geography) AS dist_meters
  FROM
    items i
  WHERE
    i.status = 'active'
    AND st_dwithin(i.location, st_point(lng, lat)::geography, radius_meters)
  ORDER BY
    st_distance(i.location, st_point(lng, lat)::geography) ASC
  LIMIT 100;
END;
$$;

-- ----------------------------------------------------------------
-- 3. Row Level Security (RLS) Policies (Example)
-- ----------------------------------------------------------------
-- For production, you should enable RLS on all tables and define
-- strict policies. For this Beta, we are keeping it simple.

-- Example for items:
-- ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Public read access for active items" ON public.items FOR SELECT USING (status = 'active');
-- CREATE POLICY "Users can manage their own items" ON public.items FOR ALL USING (auth.uid() = owner_id);

-- ----------------------------------------------------------------
-- END OF SCRIPT
-- ----------------------------------------------------------------
