CREATE TABLE IF NOT EXISTS landing.api_data (
    raw JSONB,
    loaded_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC')
);