-- Add full-text search indexes for title
CREATE INDEX IF NOT EXISTS idx_items_title_search ON items USING gin(to_tsvector('english', title));

-- Add index on category for faster filtering
CREATE INDEX IF NOT EXISTS idx_items_category ON items(category) WHERE status = 'active';

-- Add GIST index for geospatial queries
CREATE INDEX IF NOT EXISTS idx_items_location_gist ON items USING gist (location);

-- Function to search and filter items
create or replace function get_items_by_fts(
    search_term text,
    cat_filter text default null,
    min_price_filter int default 0,
    max_price_filter int default 1000000,
    swaps_filter boolean default false,
    user_lat double precision default null,
    user_lng double precision default null,
    max_dist_km int default 50,
    sort_by text default 'newest'
)
returns setof items as $$
declare
    user_location geography;
begin
    if user_lat is not null and user_lng is not null then
        user_location := st_makepoint(user_lng, user_lat)::geography;
    end if;

    return query
    select *
    from items
    where
        status = 'active'
        and (search_term is null or search_term = '' or to_tsvector('english', title) @@ plainto_tsquery('english', search_term))
        and (cat_filter is null or category = cat_filter)
        and (price >= min_price_filter and price <= max_price_filter)
        and (swaps_filter = false or accepts_swaps = true)
        and (
            user_location is null or
            (location is not null and st_dwithin(location, user_location, max_dist_km * 1000))
        )
    order by
        case when sort_by = 'newest' then created_at end desc,
        case when sort_by = 'oldest' then created_at end asc,
        case when sort_by = 'priceLowToHigh' then price end asc,
        case when sort_by = 'priceHighToLow' then price end desc,
        case when sort_by = 'nearest' and user_location is not null and location is not null then st_distance(location, user_location) end asc,
        created_at desc; -- Default fallback sort

end;
$$ language plpgsql;
