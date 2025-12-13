-- ========================================
-- BADDEL SECURITY HARDENING: Row-Level Security
-- Run this in Supabase SQL Editor IMMEDIATELY
-- ========================================

-- 1. ENABLE RLS ON ALL TABLES
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 2. USERS TABLE POLICIES
-- ========================================

-- Users can read their own profile
CREATE POLICY "users_select_own"
ON users FOR SELECT
USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "users_update_own"
ON users FOR UPDATE
USING (auth.uid() = id);

-- Anyone can read public user data (for displaying in offers)
CREATE POLICY "users_select_public"
ON users FOR SELECT
USING (true);

-- ========================================
-- 3. ITEMS TABLE POLICIES
-- ========================================

-- Anyone can view active items
CREATE POLICY "items_select_active"
ON items FOR SELECT
USING (status = 'active');

-- Users can insert their own items
CREATE POLICY "items_insert_own"
ON items FOR INSERT
WITH CHECK (auth.uid() = owner_id);

-- Users can only update/delete their own items
CREATE POLICY "items_update_own"
ON items FOR UPDATE
USING (auth.uid() = owner_id);

CREATE POLICY "items_delete_own"
ON items FOR DELETE
USING (auth.uid() = owner_id);

-- ========================================
-- 4. OFFERS TABLE POLICIES
-- ========================================

-- Users can see offers where they are buyer OR seller
CREATE POLICY "offers_select_involved"
ON offers FOR SELECT
USING (
  auth.uid() = buyer_id
  OR auth.uid() = seller_id
);

-- Users can create offers (as buyer)
CREATE POLICY "offers_insert_as_buyer"
ON offers FOR INSERT
WITH CHECK (auth.uid() = buyer_id);

-- Users can update offers if they are buyer OR seller
CREATE POLICY "offers_update_involved"
ON offers FOR UPDATE
USING (
  auth.uid() = buyer_id
  OR auth.uid() = seller_id
);

-- Prevent duplicate active offers
CREATE UNIQUE INDEX idx_unique_pending_offer
ON offers(buyer_id, target_item_id)
WHERE status = 'pending';

-- ========================================
-- 5. MESSAGES TABLE POLICIES
-- ========================================

-- Users can only read messages from their own offers
CREATE POLICY "messages_select_own_offers"
ON messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM offers
    WHERE offers.id = messages.offer_id
    AND (offers.buyer_id = auth.uid() OR offers.seller_id = auth.uid())
  )
);

-- Users can only send messages in their own offers
CREATE POLICY "messages_insert_own_offers"
ON messages FOR INSERT
WITH CHECK (
  auth.uid() = sender_id
  AND EXISTS (
    SELECT 1 FROM offers
    WHERE offers.id = messages.offer_id
    AND (offers.buyer_id = auth.uid() OR offers.seller_id = auth.uid())
  )
);

-- ========================================
-- 6. ADDITIONAL SECURITY CONSTRAINTS
-- ========================================

-- Prevent negative prices
ALTER TABLE items ADD CONSTRAINT check_positive_price
CHECK (price >= 0);

-- Prevent cash_amount in offers from being negative
ALTER TABLE offers ADD CONSTRAINT check_positive_cash
CHECK (cash_amount >= 0);

-- Ensure location is not null for active items
ALTER TABLE items ADD CONSTRAINT check_location_required
CHECK (status != 'active' OR location IS NOT NULL);

-- ========================================
-- 7. AUDIT LOGGING (Track Suspicious Activity)
-- ========================================

-- Create audit log table
CREATE TABLE IF NOT EXISTS audit_logs (
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

-- Trigger function for item deletions
CREATE OR REPLACE FUNCTION log_item_deletion()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data)
  VALUES (
    auth.uid(),
    'DELETE',
    'items',
    OLD.id::TEXT,
    row_to_json(OLD)
  );
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER audit_item_delete
BEFORE DELETE ON items
FOR EACH ROW EXECUTE FUNCTION log_item_deletion();

-- ========================================
-- 8. VERIFY SECURITY SETUP
-- ========================================

-- Test query: This should return 'RLS ENABLED' for all tables
SELECT
  schemaname,
  tablename,
  CASE WHEN rowsecurity THEN 'RLS ENABLED' ELSE 'RLS DISABLED' END as status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('users', 'items', 'offers', 'messages');

-- ========================================
-- 10. EMERGENCY KILL SWITCH
-- ========================================

-- Create function to temporarily disable suspicious accounts
CREATE OR REPLACE FUNCTION suspend_user(user_id UUID, reason TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET
    is_suspended = true,
    suspension_reason = reason,
    suspended_at = NOW()
  WHERE id = user_id;

  -- Cancel all active offers
  UPDATE offers SET status = 'cancelled'
  WHERE (buyer_id = user_id OR seller_id = user_id)
  AND status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add suspension columns if not exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspension_reason TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMPTZ;