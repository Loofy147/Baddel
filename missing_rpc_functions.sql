-- ========================================
-- MISSING RPC FUNCTIONS FOR BADDEL
-- Add these to your Supabase SQL Editor
-- ========================================

-- 1. GET NEARBY ITEMS WITH DISTANCE CALCULATION
CREATE OR REPLACE FUNCTION get_items_nearby(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_meters INTEGER DEFAULT 50000
)
RETURNS TABLE (
  id UUID,
  owner_id UUID,
  title TEXT,
  price INTEGER,
  image_url TEXT,
  accepts_swaps BOOLEAN,
  is_cash_only BOOLEAN,
  status TEXT,
  created_at TIMESTAMPTZ,
  location GEOGRAPHY,
  distance_meters DOUBLE PRECISION,
  distance_display TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validate inputs
  IF radius_meters < 100 OR radius_meters > 100000 THEN
    RAISE EXCEPTION 'Radius must be between 100m and 100km';
  END IF;

  RETURN QUERY
  SELECT
    i.id,
    i.owner_id,
    i.title,
    i.price,
    i.image_url,
    i.accepts_swaps,
    i.is_cash_only,
    i.status,
    i.created_at,
    i.location,
    ST_Distance(
      i.location::geography,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    ) as distance_meters,
    CASE
      WHEN ST_Distance(
        i.location::geography,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
      ) < 1000
      THEN ROUND(ST_Distance(
        i.location::geography,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
      ))::TEXT || ' m'
      ELSE ROUND(
        ST_Distance(
          i.location::geography,
          ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
        ) / 1000.0,
        1
      )::TEXT || ' km'
    END as distance_display
  FROM items i
  WHERE
    i.status = 'active'
    AND ST_DWithin(
      i.location::geography,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
      radius_meters
    )
    -- Don't show user their own items in the deck
    AND i.owner_id != auth.uid()
  ORDER BY distance_meters ASC
  LIMIT 100; -- Prevent DoS from loading thousands
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_items_nearby TO authenticated;

-- ========================================
-- 2. PERSONALIZED RECOMMENDATION ALGORITHM
-- (Simple version - enhance later with ML)
-- ========================================

CREATE OR REPLACE FUNCTION get_recommendations(
  user_id UUID,
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  owner_id UUID,
  title TEXT,
  price INTEGER,
  image_url TEXT,
  accepts_swaps BOOLEAN,
  distance_meters DOUBLE PRECISION,
  distance_display TEXT,
  score DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH user_interactions AS (
    -- Get user's liked categories and price ranges
    SELECT
      i.category,
      AVG(i.price) as avg_liked_price,
      COUNT(*) as interaction_count
    FROM user_interactions ui
    JOIN items i ON ui.item_id = i.id
    WHERE ui.user_id = user_id
      AND ui.action IN ('liked', 'swiped_right')
    GROUP BY i.category
  ),
  scored_items AS (
    SELECT
      i.id,
      i.owner_id,
      i.title,
      i.price,
      i.image_url,
      i.accepts_swaps,
      ST_Distance(
        i.location::geography,
        ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
      ) as distance_meters,
      CASE
        WHEN ST_Distance(
          i.location::geography,
          ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ) < 1000
        THEN ROUND(ST_Distance(
          i.location::geography,
          ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ))::TEXT || ' m'
        ELSE ROUND(
          ST_Distance(
            i.location::geography,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
          ) / 1000.0,
          1
        )::TEXT || ' km'
      END as distance_display,
      -- Scoring algorithm
      (
        -- Proximity score (50% weight)
        (1 - LEAST(ST_Distance(
          i.location::geography,
          ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ) / 50000.0, 1.0)) * 50 +

        -- Category match score (30% weight)
        COALESCE((
          SELECT 30.0 * (ui.interaction_count::FLOAT /
            (SELECT MAX(interaction_count) FROM user_interactions)
          )
          FROM user_interactions ui
          WHERE ui.category = i.category
        ), 0) +

        -- Price similarity score (20% weight)
        COALESCE((
          20.0 * (1 - ABS(i.price - (SELECT AVG(avg_liked_price) FROM user_interactions)) /
            (SELECT AVG(avg_liked_price) FROM user_interactions))
        ), 10)
      ) as score
    FROM items i
    WHERE
      i.status = 'active'
      AND i.owner_id != user_id
      AND ST_DWithin(
        i.location::geography,
        ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
        50000
      )
      -- Exclude items user already interacted with
      AND NOT EXISTS (
        SELECT 1 FROM user_interactions ui
        WHERE ui.user_id = user_id AND ui.item_id = i.id
      )
  )
  SELECT * FROM scored_items
  ORDER BY score DESC, distance_meters ASC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION get_recommendations TO authenticated;

-- ========================================
-- 3. USER INTERACTIONS TABLE
-- Track swipes for recommendations
-- ========================================

CREATE TABLE IF NOT EXISTS user_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES items(id) ON DELETE CASCADE,
  action TEXT CHECK (action IN ('liked', 'passed', 'swiped_right', 'swiped_left')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX idx_user_interactions_user_action
ON user_interactions(user_id, action, created_at);

-- RLS policies
ALTER TABLE user_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own interactions"
ON user_interactions FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own interactions"
ON user_interactions FOR SELECT
USING (auth.uid() = user_id);

-- ========================================
-- 4. TRACK SWIPE ACTIONS
-- Add this to Flutter: after each swipe, call this
-- ========================================

CREATE OR REPLACE FUNCTION record_swipe(
  p_item_id UUID,
  p_action TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO user_interactions (user_id, item_id, action)
  VALUES (auth.uid(), p_item_id, p_action)
  ON CONFLICT (user_id, item_id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION record_swipe TO authenticated;

-- ========================================
-- 5. ADD MISSING COLUMNS TO ITEMS
-- ========================================

-- Add category column for better recommendations
ALTER TABLE items ADD COLUMN IF NOT EXISTS category TEXT;

-- Create index for category searches
CREATE INDEX IF NOT EXISTS idx_items_category ON items(category);

-- Add view count for popularity
ALTER TABLE items ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;

-- ========================================
-- 6. SAFETY: PREVENT SPAM OFFERS
-- ========================================

-- This was in the previous artifact but adding again for completeness
CREATE OR REPLACE FUNCTION check_offer_spam()
RETURNS TRIGGER AS $$
DECLARE
  recent_count INTEGER;
BEGIN
  -- Check offers in last hour
  SELECT COUNT(*) INTO recent_count
  FROM offers
  WHERE buyer_id = NEW.buyer_id
  AND created_at > NOW() - INTERVAL '1 hour';

  IF recent_count >= 10 THEN
    RAISE EXCEPTION 'Rate limit: Maximum 10 offers per hour';
  END IF;

  -- Check duplicate offers for same item
  IF EXISTS (
    SELECT 1 FROM offers
    WHERE buyer_id = NEW.buyer_id
    AND target_item_id = NEW.target_item_id
    AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'You already have a pending offer for this item';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_offer_spam
BEFORE INSERT ON offers
FOR EACH ROW EXECUTE FUNCTION check_offer_spam();

-- ========================================
-- 7. VERIFY SETUP
-- ========================================

-- Run this to verify everything works
SELECT
  'Functions installed:' as check,
  COUNT(*) as count
FROM pg_proc
WHERE proname IN ('get_items_nearby', 'get_recommendations', 'record_swipe');

-- Should return count = 3