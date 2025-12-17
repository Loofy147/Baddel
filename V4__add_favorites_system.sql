-- Create favorites table
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, item_id)
);

-- Enable RLS
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Users can only see and manage their own favorites
CREATE POLICY "Users can view own favorites" ON public.favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can add favorites" ON public.favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove favorites" ON public.favorites
  FOR DELETE USING (auth.uid() = user_id);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_item_id ON public.favorites(item_id);

-- Add favorite count to items (optional, for display)
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS favorite_count INTEGER DEFAULT 0;

-- Function to increment favorite count
CREATE OR REPLACE FUNCTION increment_favorite_count(item_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE items SET favorite_count = COALESCE(favorite_count, 0) + 1
  WHERE id = item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement favorite count
CREATE OR REPLACE FUNCTION decrement_favorite_count(item_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE items SET favorite_count = GREATEST(COALESCE(favorite_count, 0) - 1, 0)
  WHERE id = item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
