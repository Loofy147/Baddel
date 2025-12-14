-- ========================================
-- BADDEL TRUST & SAFETY FEATURES
-- ========================================

-- 1. REPORTS TABLE
-- Users can report inappropriate or fraudulent items.
CREATE TABLE IF NOT EXISTS reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reported_item_id UUID REFERENCES items(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN ('spam', 'inappropriate', 'fraud', 'other')),
  notes TEXT, -- Optional additional details from the user
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Prevent a user from spam-reporting the same item
  UNIQUE (reporter_id, reported_item_id)
);

-- Add comments for clarity
COMMENT ON TABLE reports IS 'Stores user-submitted reports against items.';
COMMENT ON COLUMN reports.reason IS 'The category of the report.';

-- ========================================
-- 2. RLS POLICIES FOR REPORTS
-- ========================================

-- Enable RLS
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Users can insert a report for an item.
-- We check that the reporter_id is the same as the person inserting it.
CREATE POLICY "reports_insert_own"
ON reports FOR INSERT
WITH CHECK (auth.uid() = reporter_id);

-- Users should NOT be able to see any reports, not even their own.
-- This prevents users from checking if their report was actioned, which can lead to other issues.
-- Only service_role or admins should be able to query this table directly.

-- ========================================
-- 3. INDEXES FOR PERFORMANCE
-- ========================================

-- Create an index on the reported_item_id for faster lookups by moderators.
CREATE INDEX IF NOT EXISTS idx_reports_reported_item_id ON reports(reported_item_id);

-- ========================================
-- 4. VERIFY SETUP
-- ========================================
SELECT
  'RLS ENABLED' as status
FROM pg_tables
WHERE tablename = 'reports' AND rowsecurity = true;
