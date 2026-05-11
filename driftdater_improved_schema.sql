-- ============================================================
-- DriftDater Dating Application — PostgreSQL Database Schema
-- Revised & Optimized Version
-- INFO3180 Group Project 2025/2026
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- CLEANUP
-- ============================================================
DROP TABLE IF EXISTS notifications       CASCADE;
DROP TABLE IF EXISTS user_reports        CASCADE;
DROP TABLE IF EXISTS user_blocks         CASCADE;
DROP TABLE IF EXISTS profile_photos      CASCADE;
DROP TABLE IF EXISTS favorites           CASCADE;
DROP TABLE IF EXISTS messages            CASCADE;
DROP TABLE IF EXISTS conversations       CASCADE;
DROP TABLE IF EXISTS matches             CASCADE;
DROP TABLE IF EXISTS swipes              CASCADE;
DROP TABLE IF EXISTS user_interests      CASCADE;
DROP TABLE IF EXISTS interests           CASCADE;
DROP TABLE IF EXISTS profiles            CASCADE;
DROP TABLE IF EXISTS users               CASCADE;

DROP TYPE IF EXISTS swipe_action CASCADE;
DROP TYPE IF EXISTS gender_type CASCADE;
DROP TYPE IF EXISTS looking_for_type CASCADE;
DROP TYPE IF EXISTS relationship_goal_type CASCADE;
DROP TYPE IF EXISTS education_level_type CASCADE;
DROP TYPE IF EXISTS match_status_type CASCADE;
DROP FUNCTION IF EXISTS set_updated_at() CASCADE;

-- ============================================================
-- ENUM TYPES
-- ============================================================
CREATE TYPE swipe_action AS ENUM (
    'like',
    'dislike',
    'pass'
);

CREATE TYPE gender_type AS ENUM (
    'male',
    'female',
    'non_binary',
    'other'
);

CREATE TYPE looking_for_type AS ENUM (
    'male',
    'female',
    'non_binary',
    'any'
);

CREATE TYPE relationship_goal_type AS ENUM (
    'casual',
    'serious',
    'friendship',
    'marriage'
);

CREATE TYPE education_level_type AS ENUM (
    'high_school',
    'associate',
    'bachelors',
    'masters',
    'phd',
    'other'
);

CREATE TYPE match_status_type AS ENUM (
    'active',
    'archived',
    'blocked',
    'unmatched'
);

-- ============================================================
-- USERS
-- ============================================================
CREATE TABLE users (
    user_id                 SERIAL PRIMARY KEY,
    username                VARCHAR(50) NOT NULL UNIQUE,
    email                   VARCHAR(255) NOT NULL UNIQUE,
    password_hash           VARCHAR(255) NOT NULL,

    email_verified          BOOLEAN NOT NULL DEFAULT FALSE,
    verification_token      VARCHAR(255),
    password_reset_token    VARCHAR(255),
    password_reset_expires  TIMESTAMPTZ,

    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    last_seen_at            TIMESTAMPTZ,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_last_seen ON users(last_seen_at);

-- ============================================================
-- PROFILES
-- ============================================================
CREATE TABLE profiles (
    profile_id              SERIAL PRIMARY KEY,

    user_id                 INTEGER NOT NULL UNIQUE
                                REFERENCES users(user_id)
                                ON DELETE CASCADE,

    first_name              VARCHAR(50) NOT NULL,
    last_name               VARCHAR(50) NOT NULL,

    date_of_birth           DATE NOT NULL,

    gender                  gender_type NOT NULL,

    bio                     TEXT,

    city                    VARCHAR(100),
    country                 VARCHAR(100),

    latitude                NUMERIC(9,6),
    longitude               NUMERIC(9,6),

    looking_for             looking_for_type NOT NULL DEFAULT 'any',

    min_age_pref            SMALLINT NOT NULL DEFAULT 18
                                CHECK (min_age_pref >= 18),

    max_age_pref            SMALLINT NOT NULL DEFAULT 99
                                CHECK (max_age_pref <= 99),

    max_distance_km         SMALLINT NOT NULL DEFAULT 50,

    occupation              VARCHAR(100),

    education_level         education_level_type,

    relationship_goal       relationship_goal_type,

    is_visible              BOOLEAN NOT NULL DEFAULT TRUE,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT age_pref_check
        CHECK (min_age_pref <= max_age_pref)
);

CREATE INDEX idx_profiles_user_id
    ON profiles(user_id);

CREATE INDEX idx_profiles_location
    ON profiles(city, country);

CREATE INDEX idx_profiles_coords
    ON profiles(latitude, longitude);

CREATE INDEX idx_profiles_visible
    ON profiles(is_visible);

CREATE INDEX idx_profiles_gender
    ON profiles(gender);

CREATE INDEX idx_profiles_looking_for
    ON profiles(looking_for);

CREATE INDEX idx_profiles_relationship_goal
    ON profiles(relationship_goal);

CREATE INDEX idx_profiles_dob
    ON profiles(date_of_birth);

CREATE INDEX idx_discovery_search
    ON profiles(gender, looking_for, is_visible);

CREATE INDEX idx_profiles_bio_fts
    ON profiles
    USING GIN (to_tsvector('english', COALESCE(bio, '')));

-- ============================================================
-- INTERESTS
-- ============================================================
CREATE TABLE interests (
    interest_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50)
);

CREATE INDEX idx_interests_category
    ON interests(category);

-- ============================================================
-- USER_INTERESTS
-- ============================================================
CREATE TABLE user_interests (
    user_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    interest_id INTEGER NOT NULL
        REFERENCES interests(interest_id)
        ON DELETE CASCADE,

    PRIMARY KEY(user_id, interest_id)
);

CREATE INDEX idx_user_interests_user
    ON user_interests(user_id);

CREATE INDEX idx_user_interests_interest
    ON user_interests(interest_id);

-- ============================================================
-- SWIPES
-- ============================================================
CREATE TABLE swipes (
    swipe_id SERIAL PRIMARY KEY,

    swiper_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    swiped_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    action swipe_action NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT swipes_no_self_swipe
        CHECK (swiper_id <> swiped_id),

    CONSTRAINT swipes_unique_pair
        UNIQUE(swiper_id, swiped_id)
);

CREATE INDEX idx_swipes_swiper
    ON swipes(swiper_id);

CREATE INDEX idx_swipes_swiped
    ON swipes(swiped_id);

CREATE INDEX idx_swipes_action
    ON swipes(action);

-- ============================================================
-- MATCHES
-- ============================================================
CREATE TABLE matches (
    match_id SERIAL PRIMARY KEY,

    user1_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    user2_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    status match_status_type NOT NULL DEFAULT 'active',

    matched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT matches_no_self_match
        CHECK (user1_id <> user2_id),

    CONSTRAINT matches_order_check
        CHECK (user1_id < user2_id)
);

CREATE UNIQUE INDEX idx_matches_unique_pair
    ON matches(user1_id, user2_id);

CREATE INDEX idx_matches_user1
    ON matches(user1_id);

CREATE INDEX idx_matches_user2
    ON matches(user2_id);

CREATE INDEX idx_matches_status
    ON matches(status);

-- ============================================================
-- CONVERSATIONS
-- ============================================================
CREATE TABLE conversations (
    conversation_id SERIAL PRIMARY KEY,

    match_id INTEGER NOT NULL UNIQUE
        REFERENCES matches(match_id)
        ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_conversations_match
    ON conversations(match_id);

-- ============================================================
-- MESSAGES
-- ============================================================
CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,

    conversation_id INTEGER NOT NULL
        REFERENCES conversations(conversation_id)
        ON DELETE CASCADE,

    sender_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    body TEXT NOT NULL
        CHECK (LENGTH(TRIM(body)) > 0),

    is_read BOOLEAN NOT NULL DEFAULT FALSE,

    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation
    ON messages(conversation_id, sent_at);

CREATE INDEX idx_messages_sender
    ON messages(sender_id);

CREATE INDEX idx_messages_unread
    ON messages(conversation_id)
    WHERE NOT is_read;

-- ============================================================
-- FAVORITES
-- ============================================================
CREATE TABLE favorites (
    user_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    favorited_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY(user_id, favorited_id),

    CONSTRAINT favorites_no_self
        CHECK (user_id <> favorited_id)
);

CREATE INDEX idx_favorites_user
    ON favorites(user_id);

-- ============================================================
-- PROFILE PHOTOS
-- ============================================================
CREATE TABLE profile_photos (
    photo_id SERIAL PRIMARY KEY,

    user_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    photo_url VARCHAR(500) NOT NULL,

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profile_photos_user
    ON profile_photos(user_id);

CREATE UNIQUE INDEX idx_one_primary_photo
    ON profile_photos(user_id)
    WHERE is_primary = TRUE;

-- ============================================================
-- USER BLOCKS
-- ============================================================
CREATE TABLE user_blocks (
    blocker_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    blocked_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY(blocker_id, blocked_id),

    CONSTRAINT blocks_no_self
        CHECK (blocker_id <> blocked_id)
);

-- ============================================================
-- USER REPORTS
-- ============================================================
CREATE TABLE user_reports (
    report_id SERIAL PRIMARY KEY,

    reporter_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    reported_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    reason TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT reports_no_self
        CHECK (reporter_id <> reported_id)
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,

    user_id INTEGER NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    type VARCHAR(50) NOT NULL,

    message TEXT NOT NULL,

    is_read BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user
    ON notifications(user_id);

CREATE INDEX idx_notifications_unread
    ON notifications(user_id)
    WHERE NOT is_read;

-- ============================================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TRIGGERS
-- ============================================================
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_swipes_updated_at
BEFORE UPDATE ON swipes
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_favorites_updated_at
BEFORE UPDATE ON favorites
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_profile_photos_updated_at
BEFORE UPDATE ON profile_photos
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- SEED INTEREST DATA
-- ============================================================
INSERT INTO interests (name, category) VALUES
    ('Hiking', 'outdoors'),
    ('Photography', 'arts'),
    ('Gaming', 'tech'),
    ('Cooking', 'food'),
    ('Traveling', 'travel'),
    ('Music', 'arts'),
    ('Reading', 'education'),
    ('Fitness', 'sports'),
    ('Dancing', 'arts'),
    ('Movies', 'entertainment'),
    ('Coffee', 'food'),
    ('Yoga', 'wellness'),
    ('Painting', 'arts'),
    ('Cycling', 'sports'),
    ('Swimming', 'sports'),
    ('Volunteering', 'social'),
    ('Technology', 'tech'),
    ('Fashion', 'lifestyle'),
    ('Gardening', 'outdoors'),
    ('Board Games', 'entertainment');

-- ============================================================
-- END OF SCHEMA
-- ============================================================
```