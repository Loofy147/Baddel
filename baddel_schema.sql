-- Baddel - Supabase Database Setup SQL
-- Generated based on the Product Blueprint.
-- This script is ready to be run in the Supabase SQL Editor.

-- ----------------------------------------------------------------
-- 1. EXTENSIONS
-- ----------------------------------------------------------------
-- The PostGIS extension is required for geospatial queries (the "Radius" filter).
-- It's usually enabled by default on Supabase projects.
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;


-- ----------------------------------------------------------------
-- 2. CUSTOM TYPES (ENUMS)
-- ----------------------------------------------------------------
-- Using ENUMs makes the data more robust and queries more readable.

CREATE TYPE public.item_status AS ENUM (
  'Active',
  'Sold'
);

CREATE TYPE public.action_type AS ENUM (
  'Left_Pass',
  'Right_Cash',
  'Right_Swap'
);

CREATE TYPE public.action_status AS ENUM (
  'Pending',
  'Accepted',
  'Rejected'
);

-- ----------------------------------------------------------------
-- 3. TABLES
-- ----------------------------------------------------------------

-- ================================================================
-- USERS TABLE
-- Blueprint Section: "Database Schema (Simplified)"
-- Stores public user data. This table should be linked to Supabase's internal `auth.users` table.
-- ================================================================
CREATE TABLE public.users (
  -- `id` is the primary key and a foreign key to `auth.users.id`.
  -- This creates the one-to-one relationship with the authentication service.
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- `phone_number` is sourced from the `auth.users` table. While it can be stored here for convenience,
  -- it's often better to join with `auth.users` to get the latest value.
  -- This field is included as per the blueprint.
  phone_number TEXT,

  -- `reputation_score` for user ratings. Starts at a neutral value.
  reputation_score INT NOT NULL DEFAULT 100,

  -- `created_at` timestamp for when the user profile was created.
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add a comment explaining the purpose of the users table.
COMMENT ON TABLE public.users IS 'Stores public user profiles, linked to Supabase authentication.';


-- ================================================================
-- ITEMS TABLE
-- Blueprint Section: "Database Schema (Simplified)" & "Screen 3: The Garage"
-- Stores all items listed for sale or swap.
-- ================================================================
CREATE TABLE public.items (
  -- Using UUID for IDs makes them harder to guess and prevents enumeration attacks.
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign key to the `users` table to link items to their owners.
  -- If a user is deleted, all their items are deleted as well (ON DELETE CASCADE).
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Title and description from the "Garage" screen details.
  title TEXT NOT NULL,
  description TEXT,

  -- The blueprint mentioned an optional Voice Note. This can store the URL to the audio file.
  description_voice_url TEXT,

  -- The URL of the AI-enhanced image from Cloudinary, as per the blueprint.
  image_url TEXT NOT NULL,

  -- Storing price in the smallest currency unit (e.g., cents) avoids floating point issues.
  -- For Algerian Dinars (DA), which doesn't typically use subunits, INTEGER is fine.
  price INT NOT NULL CHECK (price >= 0),

  -- Boolean toggle for sellers who are open to swaps.
  accepts_swaps BOOLEAN NOT NULL DEFAULT FALSE,

  -- The `item_status` enum ensures only valid states can be set.
  status public.item_status NOT NULL DEFAULT 'Active',

  -- Geospatial data point for the item's location, using SRID 4326 (WGS 84).
  -- This is critical for the geofenced "Deck" screen.
  location extensions.geometry(Point, 4326),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create a GIST index on the `location` column for fast geospatial queries.
-- This is crucial for the "find items within a radius" feature.
CREATE INDEX items_location_idx ON public.items USING GIST (location);

-- Add an index on the `user_id` foreign key for faster lookups of a user's items.
CREATE INDEX items_user_id_idx ON public.items(user_id);

COMMENT ON TABLE public.items IS 'Contains all items listed by users for sale or swap.';
COMMENT ON COLUMN public.items.location IS 'Geospatial location of the item (SRID 4326).';


-- ================================================================
-- ACTIONS TABLE
-- Blueprint Section: "Database Schema (Simplified)"
-- Records every swipe action taken by users.
-- ================================================================
CREATE TABLE public.actions (
  id BIGSERIAL PRIMARY KEY,

  -- `actor_id` is the user who performed the swipe.
  actor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- `item_id` is the item that was swiped on.
  item_id UUID NOT NULL REFERENCES public.items(id) ON DELETE CASCADE,

  -- The `action_type` enum specifies what kind of swipe it was.
  type public.action_type NOT NULL,

  -- For `Right_Cash` offers, this stores the offered amount.
  offer_value INT,

  -- For `Right_Swap` offers, this links to the item being offered in return.
  offered_item_id UUID REFERENCES public.items(id) ON DELETE CASCADE,

  -- The `action_status` enum tracks the state of the offer.
  status public.action_status NOT NULL DEFAULT 'Pending',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- A user should not be able to swipe on the same item more than once.
  -- This constraint enforces that rule at the database level.
  CONSTRAINT unique_swipe_action UNIQUE (actor_id, item_id),

  -- Ensure that if it's a swap offer, the offered_item_id is not null.
  CONSTRAINT check_swap_offer CHECK ( (type = 'Right_Swap' AND offered_item_id IS NOT NULL) OR (type != 'Right_Swap') ),

  -- Ensure that if it's a cash offer, the offer_value is not null.
  CONSTRAINT check_cash_offer CHECK ( (type = 'Right_Cash' AND offer_value IS NOT NULL) OR (type != 'Right_Cash') )
);

-- Add indexes on foreign keys for performance.
CREATE INDEX actions_actor_id_idx ON public.actions(actor_id);
CREATE INDEX actions_item_id_idx ON public.actions(item_id);
CREATE INDEX actions_offered_item_id_idx ON public.actions(offered_item_id);

COMMENT ON TABLE public.actions IS 'Logs all user swipe actions (Pass, Cash Offer, Swap Offer).';


-- ================================================================
-- CHATS TABLE
-- Essential for post-match negotiation.
-- ================================================================
CREATE TABLE public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.chats IS 'Represents a chat session between two or more users.';


-- ================================================================
-- CHAT_PARTICIPANTS TABLE
-- Links users to chats.
-- ================================================================
CREATE TABLE public.chat_participants (
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  PRIMARY KEY (chat_id, user_id)
);

COMMENT ON TABLE public.chat_participants IS 'A junction table linking users to their chat sessions.';


-- ================================================================
-- MESSAGES TABLE
-- Stores individual chat messages.
-- ================================================================
CREATE TABLE public.messages (
  id BIGSERIAL PRIMARY KEY,
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add an index on chat_id for faster message lookups within a chat.
CREATE INDEX messages_chat_id_idx ON public.messages(chat_id);

COMMENT ON TABLE public.messages IS 'Stores all messages sent within chats.';


-- ----------------------------------------------------------------
-- 4. DATABASE FUNCTIONS
-- ----------------------------------------------------------------
-- This function is an example of how you would query for items within a certain radius,
-- as described in "Engine B: The Geofence".

CREATE OR REPLACE FUNCTION public.find_items_near_location(
  lat DOUBLE PRECISION,
  long DOUBLE PRECISION,
  radius_km DOUBLE PRECISION
)
RETURNS SETOF public.items
LANGUAGE sql
AS $$
  SELECT *
  FROM public.items
  WHERE
    public.items.status = 'Active' AND
    ST_DWithin(
      location::geography,
      ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
      radius_km * 1000 -- Convert km to meters
    );
$$;

COMMENT ON FUNCTION public.find_items_near_location IS 'Finds active items within a given radius (in km) from a user''s location.';

-- ----------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) - IMPORTANT!
-- ----------------------------------------------------------------
-- RLS is disabled by default. You MUST enable it for each table and
-- create policies to protect user data. Below are examples.

-- Run these commands to enable RLS:
-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.actions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Example Policies (You will need to create more specific policies for your app's logic):

-- USERS: Users can see all profiles, but can only update their own.
-- CREATE POLICY "Allow public read access" ON public.users FOR SELECT USING (true);
-- CREATE POLICY "Allow users to update their own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- ITEMS: Users can see all active items, but can only manage their own items.
-- CREATE POLICY "Allow public read access to active items" ON public.items FOR SELECT USING (status = 'Active');
-- CREATE POLICY "Allow users to manage their own items" ON public.items FOR ALL USING (auth.uid() = user_id);

-- ACTIONS: Users can only see and manage actions related to them (either as the actor or the item owner).
-- CREATE POLICY "Users can manage their own swipe actions" ON public.actions FOR ALL
--   USING (auth.uid() = actor_id)
--   WITH CHECK (auth.uid() = actor_id);

-- CREATE POLICY "Item owners can see actions on their items" ON public.actions FOR SELECT
--   USING (
--     auth.uid() IN (SELECT user_id FROM public.items WHERE id = item_id)
--   );

-- CHATS: Users can only access chats they are a part of.
-- CREATE POLICY "Allow access to own chats" ON public.chats FOR SELECT
--   USING (id IN (SELECT chat_id FROM public.chat_participants WHERE user_id = auth.uid()));

-- CHAT_PARTICIPANTS: Users can only see participants of chats they are in.
-- CREATE POLICY "Allow access to own chat participants" ON public.chat_participants FOR SELECT
--   USING (chat_id IN (SELECT chat_id FROM public.chat_participants WHERE user_id = auth.uid()));

-- MESSAGES: Users can only see messages in chats they are a part of, and can only send messages as themselves.
-- CREATE POLICY "Allow read access to messages in own chats" ON public.messages FOR SELECT
--   USING (chat_id IN (SELECT chat_id FROM public.chat_participants WHERE user_id = auth.uid()));

-- CREATE POLICY "Allow insert access to own messages" ON public.messages FOR INSERT
--   WITH CHECK (sender_id = auth.uid() AND chat_id IN (SELECT chat_id FROM public.chat_participants WHERE user_id = auth.uid()));


-- ----------------------------------------------------------------
-- END OF SCRIPT
-- ----------------------------------------------------------------
