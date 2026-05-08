-- ============================================================
-- DriftDater Dating Application — PostgreSQL Database Schema
-- INFO3180 Group Project 2025/2026
-- ============================================================

-- Enable UUID extension (optional but useful for IDs)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- CLEANUP — drop everything so the script can be re-run safely
-- ============================================================
DROP TABLE IF EXISTS profile_photos   CASCADE;
DROP TABLE IF EXISTS favorites        CASCADE;
DROP TABLE IF EXISTS messages         CASCADE;
DROP TABLE IF EXISTS conversations    CASCADE;
DROP TABLE IF EXISTS matches          CASCADE;
DROP TABLE IF EXISTS swipes           CASCADE;
DROP TABLE IF EXISTS user_interests   CASCADE;
DROP TABLE IF EXISTS interests        CASCADE;
DROP TABLE IF EXISTS profiles         CASCADE;
DROP TABLE IF EXISTS users            CASCADE;

DROP TYPE     IF EXISTS swipe_action;
DROP FUNCTION IF EXISTS set_updated_at() CASCADE;

-- ============================================================
-- 1. USERS — authentication credentials
-- ============================================================
CREATE TABLE users (
    user_id         SERIAL PRIMARY KEY,
    username        VARCHAR(50)  NOT NULL UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email    ON users (email);
CREATE INDEX idx_users_username ON users (username);


-- ============================================================
-- 2. PROFILES — extended user profile information
-- ============================================================
CREATE TABLE profiles (
    profile_id          SERIAL PRIMARY KEY,
    user_id             INTEGER      NOT NULL UNIQUE REFERENCES users (user_id) ON DELETE CASCADE,

    -- Basic info
    first_name          VARCHAR(50)  NOT NULL,
    last_name           VARCHAR(50)  NOT NULL,
    date_of_birth       DATE         NOT NULL,
    gender              VARCHAR(20)  NOT NULL,          -- e.g. 'male', 'female', 'non-binary', 'other'
    bio                 TEXT,
    profile_photo_url   VARCHAR(500),

    -- Location / geographic preferences
    city                VARCHAR(100),
    country             VARCHAR(100),
    latitude            NUMERIC(9, 6),                 -- for proximity matching
    longitude           NUMERIC(9, 6),

    -- Matching preferences
    looking_for         VARCHAR(20)  NOT NULL DEFAULT 'any',  -- 'male','female','any'
    min_age_pref        SMALLINT     NOT NULL DEFAULT 18 CHECK (min_age_pref >= 18),
    max_age_pref        SMALLINT     NOT NULL DEFAULT 99 CHECK (max_age_pref <= 99),
    max_distance_km     SMALLINT     NOT NULL DEFAULT 50,

    -- Additional custom fields (requirement: minimum 2)
    occupation          VARCHAR(100),
    education_level     VARCHAR(50),                   -- 'high_school','bachelors','masters','phd','other'
    relationship_goal   VARCHAR(50),                   -- 'casual','serious','friendship','marriage'

    -- Visibility
    is_visible          BOOLEAN      NOT NULL DEFAULT TRUE,   -- public/private toggle

    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_user_id  ON profiles (user_id);
CREATE INDEX idx_profiles_location ON profiles (city, country);
CREATE INDEX idx_profiles_coords   ON profiles (latitude, longitude);
CREATE INDEX idx_profiles_visible  ON profiles (is_visible);


-- ============================================================
-- 3. INTERESTS — normalised master list of hobbies/interests
-- ============================================================
CREATE TABLE interests (
    interest_id  SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50)                   -- e.g. 'sports','arts','music','tech','food','travel'
);

CREATE INDEX idx_interests_category ON interests (category);


-- ============================================================
-- 4. USER_INTERESTS — many-to-many: profiles ↔ interests
--    Each user must have at least 3 (enforced at application level)
-- ============================================================
CREATE TABLE user_interests (
    user_id     INTEGER NOT NULL REFERENCES users (user_id)          ON DELETE CASCADE,
    interest_id INTEGER NOT NULL REFERENCES interests (interest_id)  ON DELETE CASCADE,
    PRIMARY KEY (user_id, interest_id)
);

CREATE INDEX idx_user_interests_user     ON user_interests (user_id);
CREATE INDEX idx_user_interests_interest ON user_interests (interest_id);


-- ============================================================
-- 5. SWIPES — records every Like / Dislike / Pass action
--    A mutual Like → a confirmed Match (detected via query)
-- ============================================================
CREATE TYPE swipe_action AS ENUM ('like', 'dislike', 'pass');

CREATE TABLE swipes (
    swipe_id    SERIAL PRIMARY KEY,
    swiper_id   INTEGER      NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    swiped_id   INTEGER      NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    action      swipe_action NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT swipes_no_self_swipe CHECK (swiper_id <> swiped_id),
    CONSTRAINT swipes_unique_pair   UNIQUE (swiper_id, swiped_id)
);

CREATE INDEX idx_swipes_swiper  ON swipes (swiper_id);
CREATE INDEX idx_swipes_swiped  ON swipes (swiped_id);
CREATE INDEX idx_swipes_action  ON swipes (action);


-- ============================================================
-- 6. MATCHES — confirmed mutual likes (both users liked each other)
--    Populated by application logic or trigger when a mutual
--    like is detected in the swipes table.
-- ============================================================
CREATE TABLE matches (
    match_id    SERIAL PRIMARY KEY,
    user1_id    INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    user2_id    INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    matched_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT matches_no_self_match CHECK (user1_id <> user2_id)
);

-- Expression-based unique index prevents duplicate pairs regardless of column order
CREATE UNIQUE INDEX idx_matches_unique_pair
    ON matches (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id));

CREATE INDEX idx_matches_user1 ON matches (user1_id);
CREATE INDEX idx_matches_user2 ON matches (user2_id);


-- ============================================================
-- 7. CONVERSATIONS — messaging thread between two matched users
-- ============================================================
CREATE TABLE conversations (
    conversation_id  SERIAL PRIMARY KEY,
    match_id         INTEGER     NOT NULL UNIQUE REFERENCES matches (match_id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_conversations_match ON conversations (match_id);


-- ============================================================
-- 8. MESSAGES — individual messages within a conversation
-- ============================================================
CREATE TABLE messages (
    message_id      SERIAL PRIMARY KEY,
    conversation_id INTEGER     NOT NULL REFERENCES conversations (conversation_id) ON DELETE CASCADE,
    sender_id       INTEGER     NOT NULL REFERENCES users (user_id)                ON DELETE CASCADE,
    body            TEXT        NOT NULL CHECK (LENGTH(TRIM(body)) > 0),
    is_read         BOOLEAN     NOT NULL DEFAULT FALSE,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages (conversation_id, sent_at);
CREATE INDEX idx_messages_sender       ON messages (sender_id);
CREATE INDEX idx_messages_unread       ON messages (conversation_id) WHERE NOT is_read;


-- ============================================================
-- 9. FAVORITES — bookmarked / saved profiles
-- ============================================================
CREATE TABLE favorites (
    user_id      INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    favorited_id INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, favorited_id),
    CONSTRAINT favorites_no_self CHECK (user_id <> favorited_id)
);

CREATE INDEX idx_favorites_user ON favorites (user_id);


-- ============================================================
-- 10. PROFILE_PHOTOS — supports multiple photos per user
-- ============================================================
CREATE TABLE profile_photos (
    photo_id    SERIAL PRIMARY KEY,
    user_id     INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    photo_url   VARCHAR(500) NOT NULL,
    is_primary  BOOLEAN     NOT NULL DEFAULT FALSE,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profile_photos_user ON profile_photos (user_id);


-- ============================================================
-- AUTOMATIC updated_at TRIGGER (applies to users & profiles)
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ============================================================
-- SEED DATA — starter interests
-- ============================================================
INSERT INTO interests (name, category) VALUES
    ('Hiking',          'outdoors'),
    ('Photography',     'arts'),
    ('Gaming',          'tech'),
    ('Cooking',         'food'),
    ('Traveling',       'travel'),
    ('Music',           'arts'),
    ('Reading',         'education'),
    ('Fitness',         'sports'),
    ('Dancing',         'arts'),
    ('Movies',          'entertainment'),
    ('Coffee',          'food'),
    ('Yoga',            'wellness'),
    ('Painting',        'arts'),
    ('Cycling',         'sports'),
    ('Swimming',        'sports'),
    ('Volunteering',    'social'),
    ('Technology',      'tech'),
    ('Fashion',         'lifestyle'),
    ('Gardening',       'outdoors'),
    ('Board Games',     'entertainment');
