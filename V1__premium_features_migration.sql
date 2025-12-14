-- V1__premium_features_migration.sql

-- Initial Schema Migrations
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_score REAL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gamification_points INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1;
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_rank INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;


ALTER TABLE items ADD COLUMN IF NOT EXISTS is_boosted BOOLEAN;
ALTER TABLE items ADD COLUMN IF NOT EXISTS boost_expires_at TIMESTAMPTZ;

-- Chat Schema
CREATE TABLE IF NOT EXISTS typing_status (
  offer_id UUID REFERENCES offers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (offer_id, user_id)
);

-- Recommendation Schema
CREATE TABLE IF NOT EXISTS blocked_users (
    user_id UUID REFERENCES auth.users(id),
    blocked_user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, blocked_user_id)
);

-- Gamification Schema
CREATE TABLE IF NOT EXISTS achievements (
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

CREATE TABLE IF NOT EXISTS user_achievements (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id TEXT REFERENCES achievements(id),
  progress INTEGER DEFAULT 0,
  is_unlocked BOOLEAN DEFAULT false,
  unlocked_at TIMESTAMPTZ,
  notified BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, achievement_id)
);

CREATE TABLE IF NOT EXISTS user_stats (
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

CREATE TABLE IF NOT EXISTS daily_quests (
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

CREATE TABLE IF NOT EXISTS leaderboard_entries (
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

-- Recommendation Engine Schema Additions
CREATE TABLE IF NOT EXISTS user_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES items(id) ON DELETE CASCADE,
  action TEXT CHECK (action IN ('view', 'swipe_right', 'swipe_left', 'offer_sent', 'chat_opened', 'purchased')),
  session_id TEXT,
  duration_seconds INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

CREATE TABLE IF NOT EXISTS user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  preferred_categories JSONB DEFAULT '[]'::jsonb,
  price_range_min INTEGER DEFAULT 0,
  price_range_max INTEGER DEFAULT 1000000,
  max_distance_km INTEGER DEFAULT 50,
  prefers_swaps BOOLEAN DEFAULT false,
  preferred_times TEXT[],
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS item_scores (
  item_id UUID PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,
  quality_score FLOAT DEFAULT 0,
  popularity_score FLOAT DEFAULT 0,
  engagement_rate FLOAT DEFAULT 0,
  conversion_rate FLOAT DEFAULT 0,
  report_penalty FLOAT DEFAULT 0,
  final_score FLOAT DEFAULT 0,
  computed_at TIMESTAMPTZ DEFAULT NOW()
);


-- Functions and Triggers

-- Reputation System
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

CREATE OR REPLACE FUNCTION handle_deal_completion_for_reputation()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_reputation_score(NEW.seller_id);
    PERFORM update_reputation_score(NEW.buyer_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_deal_completed_reputation_update
AFTER UPDATE OF status ON offers
FOR EACH ROW
WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
EXECUTE FUNCTION handle_deal_completion_for_reputation();

-- Secured Analytics Functions
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

-- Gamification System Functions & Triggers
INSERT INTO achievements (id, name, description, icon, category, tier, points, requirement_type, requirement_value, badge_color, unlock_message) VALUES
('first_listing', 'First Steps', 'List your first item', '📦', 'trading', 'bronze', 10, 'count', 1, '#8B4513', 'Welcome to the marketplace!'),
('seller_5', 'Rising Seller', 'List 5 items', '🏪', 'trading', 'silver', 25, 'count', 5, '#C0C0C0', 'Your garage is growing!'),
('first_sale', 'Deal Maker', 'Complete your first sale', '💰', 'trading', 'bronze', 20, 'count', 1, '#8B4513', 'Your first deal is complete!'),
('chatty_10', 'Conversationalist', 'Send 100 messages', '💬', 'social', 'bronze', 15, 'count', 100, '#8B4513', 'You love to chat!'),
('swiper_100', 'Curious Browser', 'Swipe on 100 items', '👀', 'exploration', 'bronze', 10, 'count', 100, '#8B4513', 'Curious about everything!')
ON CONFLICT (id) DO NOTHING;

CREATE OR REPLACE FUNCTION create_user_stats_on_signup()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_stats (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_new_user_create_stats
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION create_user_stats_on_signup();

-- Recommendation Engine Functions
-- THE MASTER RECOMMENDATION FUNCTION
CREATE OR REPLACE FUNCTION get_personalized_recommendations(
  p_user_id UUID,
  p_user_lat DOUBLE PRECISION,
  p_user_lng DOUBLE PRECISION,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  item_id UUID,
  owner_id UUID,
  title TEXT,
  price INTEGER,
  image_url TEXT,
  category TEXT,
  accepts_swaps BOOLEAN,
  distance_meters DOUBLE PRECISION,
  distance_display TEXT,
  recommendation_score FLOAT,
  score_breakdown JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_prefs RECORD;
  v_avg_price_liked INTEGER;
  v_top_categories TEXT[];
  v_interaction_count INTEGER;
BEGIN
  -- Load user preferences
  SELECT * INTO v_user_prefs
  FROM user_preferences
  WHERE user_id = p_user_id;

  -- If no preferences, learn from interactions
  IF v_user_prefs IS NULL THEN
    -- Calculate average price of liked items
    SELECT
      COALESCE(AVG(i.price), 10000) INTO v_avg_price_liked
    FROM user_interactions ui
    JOIN items i ON ui.item_id = i.id
    WHERE ui.user_id = p_user_id
      AND ui.action IN ('swipe_right', 'offer_sent');

    -- Get top 3 categories user interacted with
    SELECT ARRAY_AGG(category) INTO v_top_categories
    FROM (
      SELECT i.category, COUNT(*) as cnt
      FROM user_interactions ui
      JOIN items i ON ui.item_id = i.id
      WHERE ui.user_id = p_user_id
        AND ui.action IN ('swipe_right', 'view')
      GROUP BY i.category
      ORDER BY cnt DESC
      LIMIT 3
    ) t;

    -- Create default preferences
    v_user_prefs := ROW(
      p_user_id,
      to_jsonb(COALESCE(v_top_categories, ARRAY['Electronics'])),
      GREATEST(v_avg_price_liked * 0.5, 100)::INTEGER,
      LEAST(v_avg_price_liked * 2, 1000000)::INTEGER,
      50,
      false,
      NULL,
      NOW()
    );
  END IF;

  -- Get interaction count for cold start detection
  SELECT COUNT(*) INTO v_interaction_count
  FROM user_interactions
  WHERE user_id = p_user_id;

  -- ========================================
  -- MAIN RECOMMENDATION QUERY
  -- ========================================
  RETURN QUERY
  WITH
  -- Calculate base scores
  scored_items AS (
    SELECT
      i.id as item_id,
      i.owner_id,
      i.title,
      i.price,
      i.image_url,
      i.category,
      i.accepts_swaps,

      -- Distance calculation
      ST_Distance(
        i.location::geography,
        ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography
      ) as distance_meters,

      CASE
        WHEN ST_Distance(
          i.location::geography,
          ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography
        ) < 1000
        THEN ROUND(ST_Distance(
          i.location::geography,
          ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography
        ))::TEXT || ' m'
        ELSE ROUND(
          ST_Distance(
            i.location::geography,
            ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography
          ) / 1000.0,
          1
        )::TEXT || ' km'
      END as distance_display,

      -- Scoring components (0-100 each)

      -- 1. PROXIMITY SCORE (35% weight)
      GREATEST(0, 100 - (
        ST_Distance(
          i.location::geography,
          ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography
        ) / 500.0 -- Decay: 0.2 points per 100m
      )) * 0.35 as proximity_score,

      -- 2. CATEGORY MATCH SCORE (25% weight)
      CASE
        WHEN i.category = ANY(
          SELECT jsonb_array_elements_text(v_user_prefs.preferred_categories)
        ) THEN 100
        -- Similar categories (would need a category similarity table)
        ELSE 30
      END * 0.25 as category_score,

      -- 3. PRICE AFFINITY SCORE (15% weight)
      CASE
        WHEN i.price BETWEEN v_user_prefs.price_range_min AND v_user_prefs.price_range_max
        THEN 100
        WHEN i.price < v_user_prefs.price_range_min
        THEN GREATEST(0, 100 - ((v_user_prefs.price_range_min - i.price) / 100.0))
        ELSE GREATEST(0, 100 - ((i.price - v_user_prefs.price_range_max) / 500.0))
      END * 0.15 as price_score,

      -- 4. ITEM QUALITY SCORE (10% weight)
      COALESCE(
        (SELECT final_score FROM item_scores WHERE item_id = i.id),
        50 -- Default for new items
      ) * 0.10 as quality_score,

      -- 5. FRESHNESS SCORE (10% weight)
      CASE
        WHEN i.created_at > NOW() - INTERVAL '1 day' THEN 100
        WHEN i.created_at > NOW() - INTERVAL '3 days' THEN 80
        WHEN i.created_at > NOW() - INTERVAL '7 days' THEN 60
        WHEN i.created_at > NOW() - INTERVAL '14 days' THEN 40
        ELSE 20
      END * 0.10 as freshness_score,

      -- 6. SWAP PREFERENCE ALIGNMENT (5% weight)
      CASE
        WHEN i.accepts_swaps = v_user_prefs.prefers_swaps THEN 100
        ELSE 50
      END * 0.05 as swap_score,

      -- Negative signals
      -- Penalize if user already interacted
      CASE
        WHEN EXISTS (
          SELECT 1 FROM user_interactions ui
          WHERE ui.user_id = p_user_id
            AND ui.item_id = i.id
            AND ui.action IN ('swipe_left', 'purchased')
        ) THEN -1000
        WHEN EXISTS (
          SELECT 1 FROM user_interactions ui
          WHERE ui.user_id = p_user_id
            AND ui.item_id = i.id
            AND ui.action = 'view'
            AND ui.created_at > NOW() - INTERVAL '7 days'
        ) THEN -50 -- Already seen recently
        ELSE 0
      END as interaction_penalty,

      -- Boost signals
      -- Boost if owner has good reputation
      CASE
        WHEN (SELECT reputation_score FROM users WHERE id = i.owner_id) > 80
        THEN 15
        WHEN (SELECT reputation_score FROM users WHERE id = i.owner_id) < 30
        THEN -20
        ELSE 0
      END as reputation_boost,

      -- Boost if many users liked it
      CASE
        WHEN (
          SELECT COUNT(*) FROM user_interactions
          WHERE item_id = i.id AND action = 'swipe_right'
          AND created_at > NOW() - INTERVAL '7 days'
        ) > 10 THEN 25
        ELSE 0
      END as popularity_boost,

      -- Boost boosted items (paid promotion)
      CASE
        WHEN i.is_boosted AND i.boost_expires_at > NOW() THEN 100
        ELSE 0
      END as boost_score

    FROM items i
    WHERE
      i.status = 'active'
      AND i.owner_id != p_user_id
      AND ST_DWithin(
        i.location::geography,
        ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
        v_user_prefs.max_distance_km * 1000
      )
      -- Safety: Don't show items from blocked users
      AND NOT EXISTS (
        SELECT 1 FROM blocked_users
        WHERE user_id = p_user_id AND blocked_user_id = i.owner_id
      )
  ),

  -- Calculate final scores
  final_scores AS (
    SELECT
      *,
      (
        proximity_score +
        category_score +
        price_score +
        quality_score +
        freshness_score +
        swap_score +
        interaction_penalty +
        reputation_boost +
        popularity_boost +
        boost_score
      ) as final_recommendation_score,

      jsonb_build_object(
        'proximity', ROUND(proximity_score::numeric, 2),
        'category', ROUND(category_score::numeric, 2),
        'price', ROUND(price_score::numeric, 2),
        'quality', ROUND(quality_score::numeric, 2),
        'freshness', ROUND(freshness_score::numeric, 2),
        'swap_match', ROUND(swap_score::numeric, 2),
        'reputation', ROUND(reputation_boost::numeric, 2),
        'popularity', ROUND(popularity_boost::numeric, 2),
        'boosted', ROUND(boost_score::numeric, 2)
      ) as breakdown
    FROM scored_items
  )

  -- Apply exploration vs exploitation strategy
  SELECT
    fs.item_id,
    fs.owner_id,
    fs.title,
    fs.price,
    fs.image_url,
    fs.category,
    fs.accepts_swaps,
    fs.distance_meters,
    fs.distance_display,
    fs.final_recommendation_score as recommendation_score,
    fs.breakdown as score_breakdown
  FROM final_scores fs
  WHERE
    -- Cold start: show popular items
    (v_interaction_count < 10 AND fs.popularity_boost > 0)
    OR
    -- Normal: use scores
    (v_interaction_count >= 10 AND fs.final_recommendation_score > 0)
  ORDER BY
    -- Add randomness for exploration (10% random)
    CASE
      WHEN RANDOM() < 0.1 THEN RANDOM() * 100
      ELSE fs.final_recommendation_score
    END DESC,
    fs.distance_meters ASC
  LIMIT p_limit
  OFFSET p_offset;

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

      achievement_id := v_achievement.id;
      achievement_name := v_achievement.name;
      points_earned := v_achievement.points;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$;
