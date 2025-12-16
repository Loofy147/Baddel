-- =================================================================
-- BADDEL - CONSOLIDATED DATABASE SCHEMA
-- Version: 2.0
--
-- This script contains the complete, unified schema for the Baddel application.
-- It merges the base schema, security policies, trust/safety features,
-- premium features, and RPC functions into a single source of truth.
-- Run this in your Supabase SQL Editor to set up the entire database.
-- =================================================================

-- =================================================================
-- 1. EXTENSIONS
-- =================================================================
-- These are typically enabled by default in Supabase, but are listed for completeness.
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
-- CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA extensions;

-- =================================================================
-- 2. CORE TABLES
-- =================================================================

-- Stores public user profiles, linked to Supabase authentication.
CREATE TABLE public.users (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id),
    reputation_score real DEFAULT 50.0 NOT NULL,
    badges text[] NULL,
    gamification_points integer DEFAULT 0,
    level integer DEFAULT 1,
    current_rank integer,
    is_admin boolean DEFAULT false,
    is_suspended boolean DEFAULT false,
    suspension_reason text,
    suspended_at timestamptz
);
COMMENT ON TABLE public.users IS 'Stores public user profiles, linked to Supabase authentication and app-specific data.';

-- Stores private user data, accessible only by the user.
CREATE TABLE public.user_private_data (
    id uuid NOT NULL PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    phone text NULL
);
COMMENT ON TABLE public.user_private_data IS 'Stores private user data, accessible only by the user.';

-- Contains all items listed by users for sale or swap.
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
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    category text,
    view_count integer DEFAULT 0,
    is_boosted boolean,
    boost_expires_at timestamptz,
    CONSTRAINT check_positive_price CHECK (price >= 0),
    CONSTRAINT check_location_required CHECK (status != 'active' OR location IS NOT NULL)
);
COMMENT ON TABLE public.items IS 'Contains all items listed by users for sale or swap.';

-- Manages all deal proposals (cash, swap, or hybrid).
CREATE TABLE public.offers (
    id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
    buyer_id uuid NOT NULL REFERENCES public.users(id),
    seller_id uuid NOT NULL REFERENCES public.users(id),
    target_item_id uuid NOT NULL REFERENCES public.items(id) ON DELETE CASCADE,
    offered_item_id uuid NULL REFERENCES public.items(id) ON DELETE SET NULL,
    cash_amount integer DEFAULT 0 NOT NULL,
    type text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_positive_cash CHECK (cash_amount >= 0)
);
COMMENT ON TABLE public.offers IS 'Manages all deal proposals (cash, swap, or hybrid).';

-- Real-time chat for accepted deals.
CREATE TABLE public.messages (
    id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
    offer_id uuid NOT NULL REFERENCES public.offers(id) ON DELETE CASCADE,
    sender_id uuid NOT NULL REFERENCES public.users(id),
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.messages IS 'Real-time chat for accepted deals.';

-- =================================================================
-- 3. FEATURE & SUPPORTING TABLES
-- =================================================================

-- Stores user-submitted reports against items for moderation.
CREATE TABLE public.reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reported_item_id UUID REFERENCES items(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN ('spam', 'inappropriate', 'fraud', 'other')),
  notes TEXT,
  status TEXT DEFAULT 'pending' NOT NULL, -- Added for moderation tracking
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (reporter_id, reported_item_id)
);
COMMENT ON TABLE public.reports IS 'Stores user-submitted reports against items.';

-- Tracks user swipes and interactions for the recommendation engine.
CREATE TABLE public.user_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES items(id) ON DELETE CASCADE,
  action TEXT CHECK (action IN ('view', 'swipe_right', 'swipe_left', 'offer_sent', 'chat_opened', 'purchased', 'liked', 'passed')),
  session_id TEXT,
  duration_seconds INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB,
  UNIQUE(user_id, item_id, action) -- Prevent duplicate simple actions
);
COMMENT ON TABLE public.user_interactions IS 'Tracks user interactions with items for personalization.';

-- Tracks suspicious or critical activities.
CREATE TABLE public.audit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  old_data JSONB,
  new_data JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE public.audit_logs IS 'Tracks suspicious or critical activities for security auditing.';

-- Tracks real-time typing indicators in chat.
CREATE TABLE public.typing_status (
  offer_id UUID REFERENCES offers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (offer_id, user_id)
);
COMMENT ON TABLE public.typing_status IS 'Tracks real-time typing indicators in chat.';

-- Manages user block lists to prevent interactions.
CREATE TABLE public.blocked_users (
    user_id UUID REFERENCES auth.users(id),
    blocked_user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, blocked_user_id)
);
COMMENT ON TABLE public.blocked_users IS 'Manages user block lists to prevent interactions.';

-- Stores user preferences for the recommendation engine.
CREATE TABLE public.user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  preferred_categories JSONB DEFAULT '[]'::jsonb,
  price_range_min INTEGER DEFAULT 0,
  price_range_max INTEGER DEFAULT 1000000,
  max_distance_km INTEGER DEFAULT 50,
  prefers_swaps BOOLEAN DEFAULT false,
  preferred_times TEXT[],
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE public.user_preferences IS 'Stores user preferences for the recommendation engine.';

-- Stores pre-computed scores for items to speed up recommendations.
CREATE TABLE public.item_scores (
  item_id UUID PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
  quality_score FLOAT DEFAULT 0,
  popularity_score FLOAT DEFAULT 0,
  engagement_rate FLOAT DEFAULT 0,
  conversion_rate FLOAT DEFAULT 0,
  report_penalty FLOAT DEFAULT 0,
  final_score FLOAT DEFAULT 0,
  computed_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE public.item_scores IS 'Stores pre-computed scores for items to speed up recommendations.';

-- =================================================================
-- 4. GAMIFICATION TABLES
-- =================================================================

-- Defines all available achievements in the app.
CREATE TABLE public.achievements (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  category TEXT CHECK (category IN ('trading', 'social', 'exploration', 'milestone', 'special')),
  tier TEXT CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum', 'diamond')),
  points INTEGER NOT NULL,
  requirement_type TEXT NOT NULL,
  requirement_value INTEGER,
  is_secret BOOLEAN DEFAULT false,
  badge_color TEXT NOT NULL,
  unlock_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE public.achievements IS 'Defines all available achievements in the app.';

-- Tracks the progress of each user towards unlocking achievements.
CREATE TABLE public.user_achievements (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id TEXT REFERENCES achievements(id),
  progress INTEGER DEFAULT 0,
  is_unlocked BOOLEAN DEFAULT false,
  unlocked_at TIMESTAMPTZ,
  notified BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, achievement_id)
);
COMMENT ON TABLE public.user_achievements IS 'Tracks user progress towards achievements.';

-- Stores lifetime statistics for each user.
CREATE TABLE public.user_stats (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  total_items_listed INTEGER DEFAULT 0,
  total_items_sold INTEGER DEFAULT 0,
  total_swaps_completed INTEGER DEFAULT 0,
  total_cash_deals INTEGER DEFAULT 0,
  total_offers_sent INTEGER DEFAULT 0,
  total_offers_received INTEGER DEFAULT 0,
  total_messages_sent INTEGER DEFAULT 0,
  total_swipes_right INTEGER DEFAULT 0,
  total_swipes_left INTEGER DEFAULT 0,
  current_streak_days INTEGER DEFAULT 0,
  longest_streak_days INTEGER DEFAULT 0,
  last_active_date DATE DEFAULT CURRENT_DATE,
  total_distance_explored_km INTEGER DEFAULT 0,
  reputation_boosts INTEGER DEFAULT 0,
  items_boosted INTEGER DEFAULT 0,
  perfect_deals INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
COMMENT ON TABLE public.user_stats IS 'Stores lifetime statistics for each user.';

-- Stores daily quests for users.
CREATE TABLE public.daily_quests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  quest_type TEXT NOT NULL,
  quest_description TEXT NOT NULL,
  target_value INTEGER NOT NULL,
  current_progress INTEGER DEFAULT 0,
  reward_points INTEGER NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  UNIQUE(user_id, quest_type, expires_at)
);
COMMENT ON TABLE public.daily_quests IS 'Stores personalized daily quests for users.';

-- Stores leaderboard rankings.
CREATE TABLE public.leaderboard_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  period TEXT CHECK (period IN ('daily', 'weekly', 'monthly', 'all_time')),
  metric TEXT CHECK (metric IN ('deals', 'swipes', 'reputation', 'earnings')),
  score INTEGER NOT NULL,
  rank INTEGER,
  period_start DATE NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, period, metric, period_start)
);
COMMENT ON TABLE public.leaderboard_entries IS 'Stores user rankings for various leaderboards.';

-- =================================================================
-- 5. INDEXES
-- =================================================================

-- Core Tables
CREATE INDEX IF NOT EXISTS idx_items_owner_id ON items(owner_id);
CREATE INDEX IF NOT EXISTS idx_items_location ON items USING gist (location);
CREATE INDEX IF NOT EXISTS idx_offers_buyer_seller_id ON offers(buyer_id, seller_id);
CREATE INDEX IF NOT EXISTS idx_messages_offer_id ON messages(offer_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_pending_offer ON offers(buyer_id, target_item_id) WHERE status = 'pending';

-- Feature Tables
CREATE INDEX IF NOT EXISTS idx_reports_reported_item_id ON reports(reported_item_id);
CREATE INDEX IF NOT EXISTS idx_user_interactions_user_action ON user_interactions(user_id, action, created_at);
CREATE INDEX IF NOT EXISTS idx_user_interactions_item_action ON user_interactions(item_id, action, created_at);
CREATE INDEX IF NOT EXISTS idx_items_category ON items(category);
CREATE INDEX IF NOT EXISTS idx_items_status_owner ON items(status, owner_id);

-- =================================================================
-- 6. FUNCTIONS & TRIGGERS
-- =================================================================

-- ---------------------------------
-- User & Stats Management
-- ---------------------------------

-- Creates associated public and private user entries on new user signup.
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create a public user profile. This is necessary to link the auth user to app-specific data.
    INSERT INTO public.users (id) VALUES (NEW.id);

    -- Create a private user data entry, linked to the new public profile.
    INSERT INTO public.user_private_data (id, phone) VALUES (NEW.id, NEW.phone);

    -- Create a user stats entry.
    INSERT INTO public.user_stats (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for the above function.
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ---------------------------------
-- Security & Auditing
-- ---------------------------------

-- Logs item deletions to the audit_logs table.
CREATE OR REPLACE FUNCTION log_item_deletion()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data)
  VALUES (auth.uid(), 'DELETE', 'items', OLD.id::TEXT, row_to_json(OLD));
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for the above function.
CREATE TRIGGER audit_item_delete
BEFORE DELETE ON items
FOR EACH ROW EXECUTE FUNCTION log_item_deletion();


-- Prevents offer spamming.
CREATE OR REPLACE FUNCTION check_offer_spam()
RETURNS TRIGGER AS $$
DECLARE
  recent_count INTEGER;
BEGIN
  -- Rate limit: check offers in the last hour.
  SELECT COUNT(*) INTO recent_count
  FROM offers
  WHERE buyer_id = NEW.buyer_id AND created_at > NOW() - INTERVAL '1 hour';

  IF recent_count >= 10 THEN
    RAISE EXCEPTION 'Rate limit: Maximum 10 offers per hour';
  END IF;

  -- Prevent duplicate pending offers.
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

-- Trigger for the above function.
CREATE TRIGGER prevent_offer_spam
BEFORE INSERT ON offers
FOR EACH ROW EXECUTE FUNCTION check_offer_spam();

-- ---------------------------------
-- Gamification & Reputation
-- ---------------------------------

-- Updates a user's reputation score based on completed deals.
CREATE OR REPLACE FUNCTION update_reputation_score(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    completed_deals INT;
    new_score REAL;
BEGIN
    SELECT COUNT(*) INTO completed_deals FROM offers WHERE (seller_id = p_user_id OR buyer_id = p_user_id) AND status = 'completed';
    new_score := 50 + (completed_deals * 5);
    IF new_score > 100 THEN new_score := 100; END IF;
    UPDATE users SET reputation_score = new_score WHERE id = p_user_id;
END;
$$;

-- Trigger helper for reputation updates.
CREATE OR REPLACE FUNCTION handle_deal_completion_for_reputation()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_reputation_score(NEW.seller_id);
    PERFORM update_reputation_score(NEW.buyer_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for the above function.
CREATE TRIGGER on_deal_completed_reputation_update
AFTER UPDATE OF status ON offers
FOR EACH ROW
WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
EXECUTE FUNCTION handle_deal_completion_for_reputation();

-- Checks and unlocks achievements for a user based on their stats.
CREATE OR REPLACE FUNCTION check_and_unlock_achievements(p_user_id UUID)
RETURNS TABLE (
  achievement_id TEXT,
  achievement_name TEXT,
  points_earned INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_stats RECORD;
  v_achievement RECORD;
  v_progress INTEGER;
BEGIN
  SELECT * INTO v_stats FROM user_stats WHERE user_id = p_user_id;
  IF v_stats IS NULL THEN
    INSERT INTO user_stats (user_id) VALUES (p_user_id) RETURNING * INTO v_stats;
  END IF;

  FOR v_achievement IN SELECT * FROM achievements LOOP
    v_progress := 0;

    CASE v_achievement.requirement_type
      WHEN 'count' THEN
        CASE v_achievement.id
          WHEN 'first_listing' THEN v_progress := v_stats.total_items_listed;
          WHEN 'seller_5' THEN v_progress := v_stats.total_items_listed;
          WHEN 'first_sale' THEN v_progress := v_stats.total_items_sold;
          WHEN 'chatty_10' THEN v_progress := v_stats.total_messages_sent;
          WHEN 'swiper_100' THEN v_progress := v_stats.total_swipes_right + v_stats.total_swipes_left;
          ELSE v_progress := 0;
        END CASE;
      ELSE v_progress := 0;
    END CASE;

    INSERT INTO user_achievements (user_id, achievement_id, progress)
    VALUES (p_user_id, v_achievement.id, v_progress)
    ON CONFLICT (user_id, achievement_id)
    DO UPDATE SET progress = v_progress, updated_at = NOW();

    IF v_progress >= v_achievement.requirement_value AND NOT EXISTS (
      SELECT 1 FROM user_achievements WHERE user_id = p_user_id AND achievement_id = v_achievement.id AND is_unlocked = true
    ) THEN
      UPDATE user_achievements
      SET is_unlocked = true, unlocked_at = NOW(), notified = false
      WHERE user_id = p_user_id AND achievement_id = v_achievement.id;

      UPDATE users
      SET gamification_points = COALESCE(gamification_points, 0) + v_achievement.points
      WHERE id = p_user_id;

      -- Assign to output variables
      check_and_unlock_achievements.achievement_id := v_achievement.id;
      check_and_unlock_achievements.achievement_name := v_achievement.name;
      check_and_unlock_achievements.points_earned := v_achievement.points;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$;

-- =================================================================
-- 7. RPC FUNCTIONS (for client-side calls)
-- =================================================================

-- ---------------------------------
-- Core App Logic RPCs
-- ---------------------------------

-- Fetches nearby items with distance calculated.
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
  IF radius_meters < 100 OR radius_meters > 100000 THEN
    RAISE EXCEPTION 'Radius must be between 100m and 100km';
  END IF;

  RETURN QUERY
  SELECT
    i.id, i.owner_id, i.title, i.price, i.image_url, i.accepts_swaps,
    i.is_cash_only, i.status, i.created_at, i.location,
    ST_Distance(i.location::geography, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography) as distance_meters,
    CASE
      WHEN ST_Distance(i.location::geography, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography) < 1000
      THEN ROUND(ST_Distance(i.location::geography, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography))::TEXT || ' m'
      ELSE ROUND(ST_Distance(i.location::geography, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography) / 1000.0, 1)::TEXT || ' km'
    END as distance_display
  FROM items i
  WHERE i.status = 'active'
    AND ST_DWithin(i.location::geography, ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography, radius_meters)
    AND i.owner_id != auth.uid()
  ORDER BY distance_meters ASC
  LIMIT 100;
END;
$$;
GRANT EXECUTE ON FUNCTION get_items_nearby TO authenticated;

-- Records a user's swipe action.
CREATE OR REPLACE FUNCTION record_swipe(p_item_id UUID, p_action TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO user_interactions (user_id, item_id, action)
  VALUES (auth.uid(), p_item_id, p_action)
  ON CONFLICT (user_id, item_id, action) DO NOTHING;
END;
$$;
GRANT EXECUTE ON FUNCTION record_swipe TO authenticated;

-- Suspends a user account and cancels their active offers.
CREATE OR REPLACE FUNCTION suspend_user(user_id UUID, reason TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET
    is_suspended = true,
    suspension_reason = reason,
    suspended_at = NOW()
  WHERE id = user_id;

  UPDATE offers SET status = 'cancelled'
  WHERE (buyer_id = user_id OR seller_id = user_id)
  AND status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- NOTE: Grant access to admins only via role-based security.

-- ---------------------------------
-- Recommendation Engine RPCs
-- ---------------------------------

-- THE MASTER RECOMMENDATION FUNCTION
-- THE MASTER RECOMMENDATION FUNCTION (v2 - Optimized)
CREATE OR REPLACE FUNCTION get_personalized_recommendations(
  p_user_id UUID,
  p_user_lat DOUBLE PRECISION,
  p_user_lng DOUBLE PRECISION,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  item_id UUID, owner_id UUID, title TEXT, price INTEGER, image_url TEXT,
  category TEXT, accepts_swaps BOOLEAN, distance_meters DOUBLE PRECISION,
  distance_display TEXT, recommendation_score FLOAT, score_breakdown JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_prefs RECORD;
  v_interaction_count INTEGER;
  v_user_location GEOGRAPHY;
BEGIN
  -- Fetch user preferences and interaction count in one go
  SELECT up.*, (SELECT COUNT(*) FROM user_interactions WHERE user_id = p_user_id)
  INTO v_user_prefs, v_interaction_count
  FROM user_preferences up
  WHERE up.user_id = p_user_id;

  -- Create default preferences if none exist
  IF v_user_prefs IS NULL THEN
    INSERT INTO user_preferences(user_id) VALUES (p_user_id) RETURNING * INTO v_user_prefs;
    v_interaction_count := 0;
  END IF;

  v_user_location := ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326);

  RETURN QUERY
  WITH relevant_items AS (
    SELECT i.*
    FROM items i
    WHERE i.status = 'active'
      AND i.owner_id != p_user_id
      AND ST_DWithin(i.location, v_user_location, v_user_prefs.max_distance_km * 1000)
      AND NOT EXISTS (
        SELECT 1 FROM blocked_users bu
        WHERE (bu.user_id = p_user_id AND bu.blocked_user_id = i.owner_id)
           OR (bu.user_id = i.owner_id AND bu.blocked_user_id = p_user_id)
      )
  ),
  scored_items AS (
    SELECT
      i.id as item_id, i.owner_id, i.title, i.price, i.image_url, i.category, i.accepts_swaps,
      -- Performance: Pre-fetch scores and join instead of correlated subqueries
      COALESCE(isc.final_score, 50) as quality_score,
      u.reputation_score,
      ST_Distance(i.location, v_user_location) as distance,
      -- Check for swipe left/purchased in a single join
      (ui.action IS NOT NULL) as has_negative_interaction,
      (pop.swipe_count > 10) as is_popular,
      i.created_at,
      i.is_boosted,
      i.boost_expires_at
    FROM relevant_items i
    LEFT JOIN item_scores isc ON i.id = isc.item_id
    LEFT JOIN users u ON i.owner_id = u.id
    -- Join to find negative interactions
    LEFT JOIN user_interactions ui ON i.id = ui.item_id AND ui.user_id = p_user_id AND ui.action IN ('swipe_left', 'purchased')
    -- Join to calculate popularity
    LEFT JOIN (
        SELECT item_id, COUNT(*) as swipe_count
        FROM user_interactions
        WHERE action = 'swipe_right' AND created_at > NOW() - INTERVAL '7 days'
        GROUP BY item_id
    ) pop ON i.id = pop.item_id
  ),
  final_scores AS (
    SELECT
      *,
      -- Score Calculation (moved from main query to CTE for clarity)
      GREATEST(0, 100 - (distance / 500.0)) * 0.35 +                                  -- proximity_score
      CASE WHEN category = ANY(SELECT jsonb_array_elements_text(v_user_prefs.preferred_categories)) THEN 100 ELSE 30 END * 0.25 + -- category_score
      CASE WHEN price BETWEEN v_user_prefs.price_range_min AND v_user_prefs.price_range_max THEN 100 ELSE GREATEST(0, 100 - (ABS(price - (v_user_prefs.price_range_min + v_user_prefs.price_range_max)/2.0)) / 500.0) END * 0.15 + -- price_score
      quality_score * 0.10 +                                                            -- quality_score
      CASE WHEN created_at > NOW() - INTERVAL '3 days' THEN 100 WHEN created_at > NOW() - INTERVAL '7 days' THEN 60 ELSE 20 END * 0.10 + -- freshness_score
      CASE WHEN accepts_swaps = v_user_prefs.prefers_swaps THEN 100 ELSE 50 END * 0.05 + -- swap_score
      CASE WHEN has_negative_interaction THEN -1000 ELSE 0 END +                        -- interaction_penalty
      CASE WHEN reputation_score > 80 THEN 15 WHEN reputation_score < 30 THEN -20 ELSE 0 END + -- reputation_boost
      CASE WHEN is_popular THEN 25 ELSE 0 END +                                         -- popularity_boost
      CASE WHEN is_boosted AND boost_expires_at > NOW() THEN 100 ELSE 0 END             -- boost_score
      as final_score
    FROM scored_items
  )
  SELECT
    fs.item_id, fs.owner_id, fs.title, fs.price, fs.image_url, fs.category, fs.accepts_swaps,
    fs.distance as distance_meters,
    CASE WHEN fs.distance < 1000 THEN ROUND(fs.distance)::TEXT || ' m' ELSE ROUND(fs.distance / 1000.0, 1)::TEXT || ' km' END as distance_display,
    fs.final_score as recommendation_score,
    jsonb_build_object(
        'proximity', ROUND((GREATEST(0, 100 - (fs.distance / 500.0)) * 0.35)::numeric, 2),
        'category', ROUND((CASE WHEN fs.category = ANY(SELECT jsonb_array_elements_text(v_user_prefs.preferred_categories)) THEN 100 ELSE 30 END * 0.25)::numeric, 2),
        'price', ROUND((CASE WHEN fs.price BETWEEN v_user_prefs.price_range_min AND v_user_prefs.price_range_max THEN 100 ELSE GREATEST(0, 100 - (ABS(fs.price - (v_user_prefs.price_range_min + v_user_prefs.price_range_max)/2.0)) / 500.0) END * 0.15)::numeric, 2)
    ) as score_breakdown
  FROM final_scores fs
  -- Filter out negatively interacted items and apply logic for new vs. existing users
  WHERE NOT fs.has_negative_interaction
    AND (v_interaction_count < 10 AND fs.is_popular OR v_interaction_count >= 10)
  ORDER BY CASE WHEN RANDOM() < 0.1 THEN RANDOM() * 100 ELSE fs.final_score END DESC, fs.distance ASC
  LIMIT p_limit OFFSET p_offset;
END;
$$;
GRANT EXECUTE ON FUNCTION get_personalized_recommendations TO authenticated;

-- BATCH JOB: UPDATE ITEM QUALITY SCORES
CREATE OR REPLACE FUNCTION update_item_quality_scores()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO item_scores (item_id, quality_score, popularity_score, engagement_rate, conversion_rate, report_penalty, final_score)
  SELECT
    i.id as item_id,

    -- Quality score based on image, description, etc.
    CASE
      WHEN LENGTH(i.title) > 20 THEN 80
      WHEN LENGTH(i.title) > 10 THEN 60
      ELSE 40
    END as quality_score,

    -- Popularity (views + likes)
    LEAST(100, (
      SELECT COUNT(*) * 5
      FROM user_interactions
      WHERE item_id = i.id
        AND action IN ('view', 'swipe_right')
        AND created_at > NOW() - INTERVAL '7 days'
    )) as popularity_score,

    -- Engagement rate (likes / views)
    CASE
      WHEN (SELECT COUNT(*) FROM user_interactions WHERE item_id = i.id AND action = 'view') > 0
      THEN (
        (SELECT COUNT(*) FROM user_interactions WHERE item_id = i.id AND action = 'swipe_right')::FLOAT /
        (SELECT COUNT(*) FROM user_interactions WHERE item_id = i.id AND action = 'view')::FLOAT
      ) * 100
      ELSE 0
    END as engagement_rate,

    -- Conversion rate (offers / views)
    CASE
      WHEN (SELECT COUNT(*) FROM user_interactions WHERE item_id = i.id AND action = 'view') > 10
      THEN (
        (SELECT COUNT(*) FROM offers WHERE target_item_id = i.id)::FLOAT /
        (SELECT COUNT(*) FROM user_interactions WHERE item_id = i.id AND action = 'view')::FLOAT
      ) * 100
      ELSE 0
    END as conversion_rate,

    -- Report penalty
    (SELECT COUNT(*) * -20 FROM reports WHERE reported_item_id = i.id AND status = 'confirmed') as report_penalty,

    -- Final score (weighted average)
    (
      (CASE WHEN LENGTH(i.title) > 20 THEN 80 WHEN LENGTH(i.title) > 10 THEN 60 ELSE 40 END) * 0.2 +
      LEAST(100, (SELECT COUNT(*) * 5 FROM user_interactions WHERE item_id = i.id AND action IN ('view', 'swipe_right'))) * 0.3 +
      COALESCE((SELECT COUNT(*) * -20 FROM reports WHERE reported_item_id = i.id), 0) * 0.5
    ) as final_score

  FROM items i
  WHERE i.status = 'active'
  ON CONFLICT (item_id)
  DO UPDATE SET
    quality_score = EXCLUDED.quality_score,
    popularity_score = EXCLUDED.popularity_score,
    engagement_rate = EXCLUDED.engagement_rate,
    conversion_rate = EXCLUDED.conversion_rate,
    report_penalty = EXCLUDED.report_penalty,
    final_score = EXCLUDED.final_score,
    computed_at = NOW();
END;
$$;

-- HELPER: UPDATE USER PREFERENCES
CREATE OR REPLACE FUNCTION update_user_preferences(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_top_categories JSONB;
  v_avg_price_min INTEGER;
  v_avg_price_max INTEGER;
  v_prefers_swaps BOOLEAN;
BEGIN
  -- Learn preferred categories
  SELECT to_jsonb(ARRAY_AGG(category)) INTO v_top_categories
  FROM (
    SELECT i.category, COUNT(*) as cnt
    FROM user_interactions ui
    JOIN items i ON ui.item_id = i.id
    WHERE ui.user_id = p_user_id
      AND ui.action IN ('swipe_right', 'offer_sent')
    GROUP BY i.category
    ORDER BY cnt DESC
    LIMIT 5
  ) t;

  -- Learn price range
  SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY i.price)::INTEGER,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY i.price)::INTEGER
  INTO v_avg_price_min, v_avg_price_max
  FROM user_interactions ui
  JOIN items i ON ui.item_id = i.id
  WHERE ui.user_id = p_user_id
    AND ui.action IN ('swipe_right', 'offer_sent');

  -- Learn swap preference
  SELECT
    (COUNT(*) FILTER (WHERE i.accepts_swaps = true))::FLOAT /
    NULLIF(COUNT(*)::FLOAT, 0) > 0.5
  INTO v_prefers_swaps
  FROM user_interactions ui
  JOIN items i ON ui.item_id = i.id
  WHERE ui.user_id = p_user_id
    AND ui.action = 'swipe_right';

  -- Update or insert
  INSERT INTO user_preferences (
    user_id,
    preferred_categories,
    price_range_min,
    price_range_max,
    prefers_swaps,
    updated_at
  )
  VALUES (
    p_user_id,
    COALESCE(v_top_categories, '["Electronics"]'::jsonb),
    COALESCE(v_avg_price_min, 1000),
    COALESCE(v_avg_price_max, 50000),
    COALESCE(v_prefers_swaps, false),
    NOW()
  )
  ON CONFLICT (user_id)
  DO UPDATE SET
    preferred_categories = EXCLUDED.preferred_categories,
    price_range_min = EXCLUDED.price_range_min,
    price_range_max = EXCLUDED.price_range_max,
    prefers_swaps = EXCLUDED.prefers_swaps,
    updated_at = NOW();
END;
$$;

-- ---------------------------------
-- Admin & Analytics RPCs
-- ---------------------------------

-- Fetches a high-level overview of app analytics. Admin only.
CREATE OR REPLACE FUNCTION get_analytics_overview(time_interval text)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    is_admin_user BOOLEAN;
BEGIN
    SELECT is_admin INTO is_admin_user FROM public.users WHERE id = auth.uid();
    IF NOT is_admin_user THEN RAISE EXCEPTION 'User is not an admin'; END IF;

    RETURN (SELECT json_build_object(
        'total_users', (SELECT count(*) FROM auth.users),
        'new_users', (SELECT count(*) FROM auth.users WHERE created_at >= NOW() - time_interval::interval),
        'active_items', (SELECT count(*) FROM items WHERE status = 'active'),
        'new_items', (SELECT count(*) FROM items WHERE created_at >= NOW() - time_interval::interval),
        'total_offers', (SELECT count(*) FROM offers),
        'revenue', (SELECT COALESCE(SUM(cash_amount) * 0.05, 0)::INT FROM offers WHERE status = 'completed')
    ));
END;
$$;
-- NOTE: Grant execute to an 'admin' role in production.

-- Fetches user growth data for charts. Admin only.
CREATE OR REPLACE FUNCTION get_user_growth(time_interval text)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    is_admin_user BOOLEAN;
BEGIN
    SELECT is_admin INTO is_admin_user FROM public.users WHERE id = auth.uid();
    IF NOT is_admin_user THEN RAISE EXCEPTION 'User is not an admin'; END IF;

    RETURN (SELECT json_agg(t) FROM (
        SELECT date_trunc('day', created_at)::date AS date, count(*)::int AS count
        FROM auth.users
        WHERE created_at >= NOW() - time_interval::interval
        GROUP BY date_trunc('day', created_at)
        ORDER BY date
    ) t);
END;
$$;
-- NOTE: Grant execute to an 'admin' role in production.


-- =================================================================
-- 8. ROW-LEVEL SECURITY (RLS) POLICIES
-- =================================================================

-- Enable RLS on all relevant tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_private_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interactions ENABLE ROW LEVEL SECURITY;
-- Other tables like achievements are public or managed by triggers/functions.

-- USERS Table (Public Profiles)
-- Any authenticated user can view public profiles.
CREATE POLICY "users_select_all_authenticated" ON users FOR SELECT USING (true);
-- Users can only update their own profile.
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (auth.uid() = id);

-- USER_PRIVATE_DATA Table
-- Users can only access their own private data.
CREATE POLICY "user_private_data_all_own" ON user_private_data FOR ALL USING (auth.uid() = id);

-- ITEMS Table
-- Users can see active items, except those from users they've blocked or who have blocked them.
CREATE POLICY "items_select_active" ON items FOR SELECT USING (
    status = 'active' AND
    NOT EXISTS (
        SELECT 1 FROM blocked_users
        WHERE
            (blocked_users.user_id = auth.uid() AND blocked_users.blocked_user_id = items.owner_id) OR
            (blocked_users.user_id = items.owner_id AND blocked_users.blocked_user_id = auth.uid())
    )
);
-- Users can insert items they own.
CREATE POLICY "items_insert_own" ON items FOR INSERT WITH CHECK (auth.uid() = owner_id);
-- Users can update their own items.
CREATE POLICY "items_update_own" ON items FOR UPDATE USING (auth.uid() = owner_id);
-- Users can delete their own items.
CREATE POLICY "items_delete_own" ON items FOR DELETE USING (auth.uid() = owner_id);

-- OFFERS Table
CREATE POLICY "offers_select_involved" ON offers FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "offers_insert_as_buyer" ON offers FOR INSERT WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "offers_update_involved" ON offers FOR UPDATE USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- MESSAGES Table
CREATE POLICY "messages_select_own_offers" ON messages FOR SELECT USING (EXISTS (SELECT 1 FROM offers WHERE offers.id = messages.offer_id AND (offers.buyer_id = auth.uid() OR offers.seller_id = auth.uid())));
CREATE POLICY "messages_insert_own_offers" ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id AND EXISTS (SELECT 1 FROM offers WHERE offers.id = messages.offer_id AND (offers.buyer_id = auth.uid() OR offers.seller_id = auth.uid())));

-- REPORTS Table
CREATE POLICY "reports_insert_own" ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
-- Note: There is NO SELECT policy on reports for regular users.

-- USER_INTERACTIONS Table
CREATE POLICY "Users can manage their own interactions" ON user_interactions FOR ALL USING (auth.uid() = user_id);

-- =================================================================
-- 9. SEED DATA
-- =================================================================

INSERT INTO achievements (id, name, description, icon, category, tier, points, requirement_type, requirement_value, badge_color, unlock_message) VALUES
('first_listing', 'First Steps', 'List your first item', '📦', 'trading', 'bronze', 10, 'count', 1, '#8B4513', 'Welcome to the marketplace!'),
('seller_5', 'Rising Seller', 'List 5 items', '🏪', 'trading', 'silver', 25, 'count', 5, '#C0C0C0', 'Your garage is growing!'),
('first_sale', 'Deal Maker', 'Complete your first sale', '💰', 'trading', 'bronze', 20, 'count', 1, '#8B4513', 'Your first deal is complete!'),
('chatty_10', 'Conversationalist', 'Send 100 messages', '💬', 'social', 'bronze', 15, 'count', 100, '#8B4513', 'You love to chat!'),
('swiper_100', 'Curious Browser', 'Swipe on 100 items', '👀', 'exploration', 'bronze', 10, 'count', 100, '#8B4513', 'Curious about everything!')
ON CONFLICT (id) DO NOTHING;

-- =================================================================
-- 10. VERIFICATION
-- =================================================================
/*
-- Run this query to check RLS status on core tables.
-- It should return 'RLS ENABLED' for all listed tables.
SELECT
  tablename,
  CASE WHEN rowsecurity THEN 'RLS ENABLED' ELSE 'RLS DISABLED' END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'items', 'offers', 'messages', 'reports', 'user_interactions');
*/

-- =================================================================
-- END OF SCRIPT
-- =================================================================
