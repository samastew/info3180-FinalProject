-- ============================================================
-- DriftDater — Complete Schema + Seed Data (Fixed)
-- Run this file fresh in psql after dropping existing tables
-- ============================================================

BEGIN;

-- ============================================================
-- CLEANUP
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
DROP TYPE  IF EXISTS swipe_action;

-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE users (
    user_id       SERIAL PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_users_email    ON users (email);
CREATE INDEX idx_users_username ON users (username);

-- ============================================================
-- 2. INTERESTS (before profiles and user_interests)
-- ============================================================
CREATE TABLE interests (
    interest_id SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    category    VARCHAR(50)
);
CREATE INDEX idx_interests_category ON interests (category);

-- ============================================================
-- 3. PROFILES
-- ============================================================
CREATE TABLE profiles (
    profile_id          SERIAL PRIMARY KEY,
    user_id             INTEGER      NOT NULL UNIQUE REFERENCES users (user_id) ON DELETE CASCADE,
    first_name          VARCHAR(50)  NOT NULL,
    last_name           VARCHAR(50)  NOT NULL,
    date_of_birth       DATE         NOT NULL,
    gender              VARCHAR(20)  NOT NULL,
    bio                 TEXT,
    profile_photo_url   VARCHAR(500),
    city                VARCHAR(100),
    country             VARCHAR(100),
    latitude            NUMERIC(9, 6),
    longitude           NUMERIC(9, 6),
    looking_for         VARCHAR(20)  NOT NULL DEFAULT 'any',
    min_age_pref        SMALLINT     NOT NULL DEFAULT 18 CHECK (min_age_pref >= 18),
    max_age_pref        SMALLINT     NOT NULL DEFAULT 99 CHECK (max_age_pref <= 99),
    max_distance_km     SMALLINT     NOT NULL DEFAULT 50,
    occupation          VARCHAR(100),
    education_level     VARCHAR(50),
    relationship_goal   VARCHAR(50),
    is_visible          BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_profiles_user_id  ON profiles (user_id);
CREATE INDEX idx_profiles_location ON profiles (city, country);
CREATE INDEX idx_profiles_coords   ON profiles (latitude, longitude);
CREATE INDEX idx_profiles_visible  ON profiles (is_visible);

-- ============================================================
-- 4. USER_INTERESTS
-- ============================================================
CREATE TABLE user_interests (
    user_id     INTEGER NOT NULL REFERENCES users     (user_id)      ON DELETE CASCADE,
    interest_id INTEGER NOT NULL REFERENCES interests (interest_id)  ON DELETE CASCADE,
    PRIMARY KEY (user_id, interest_id)
);
CREATE INDEX idx_user_interests_user     ON user_interests (user_id);
CREATE INDEX idx_user_interests_interest ON user_interests (interest_id);

-- ============================================================
-- 5. SWIPES  — VARCHAR instead of ENUM so SQLAlchemy String(10) works
-- ============================================================
CREATE TABLE swipes (
    swipe_id   SERIAL PRIMARY KEY,
    swiper_id  INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    swiped_id  INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    action     VARCHAR(10) NOT NULL CHECK (action IN ('like','dislike','pass')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT swipes_no_self_swipe CHECK (swiper_id <> swiped_id),
    CONSTRAINT swipes_unique_pair   UNIQUE (swiper_id, swiped_id)
);
CREATE INDEX idx_swipes_swiper ON swipes (swiper_id);
CREATE INDEX idx_swipes_swiped ON swipes (swiped_id);
CREATE INDEX idx_swipes_action ON swipes (action);

-- ============================================================
-- 6. MATCHES
-- ============================================================
CREATE TABLE matches (
    match_id   SERIAL PRIMARY KEY,
    user1_id   INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    user2_id   INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    matched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT matches_no_self_match CHECK (user1_id <> user2_id)
);
CREATE UNIQUE INDEX idx_matches_unique_pair
    ON matches (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id));
CREATE INDEX idx_matches_user1 ON matches (user1_id);
CREATE INDEX idx_matches_user2 ON matches (user2_id);

-- ============================================================
-- 7. CONVERSATIONS
-- ============================================================
CREATE TABLE conversations (
    conversation_id SERIAL PRIMARY KEY,
    match_id        INTEGER     NOT NULL UNIQUE REFERENCES matches (match_id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_conversations_match ON conversations (match_id);

-- ============================================================
-- 8. MESSAGES
-- ============================================================
CREATE TABLE messages (
    message_id      SERIAL PRIMARY KEY,
    conversation_id INTEGER     NOT NULL REFERENCES conversations (conversation_id) ON DELETE CASCADE,
    sender_id       INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    body            TEXT        NOT NULL CHECK (LENGTH(TRIM(body)) > 0),
    is_read         BOOLEAN     NOT NULL DEFAULT FALSE,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_messages_conversation ON messages (conversation_id, sent_at);
CREATE INDEX idx_messages_sender       ON messages (sender_id);
CREATE INDEX idx_messages_unread       ON messages (conversation_id) WHERE NOT is_read;

-- ============================================================
-- 9. FAVORITES
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
-- 10. PROFILE_PHOTOS
-- ============================================================
CREATE TABLE profile_photos (
    photo_id    SERIAL PRIMARY KEY,
    user_id     INTEGER      NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    photo_url   VARCHAR(500) NOT NULL,
    is_primary  BOOLEAN      NOT NULL DEFAULT FALSE,
    uploaded_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_profile_photos_user ON profile_photos (user_id);

-- ============================================================
-- TRIGGERS for updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ============================================================
-- USERS
-- ============================================================
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (1, 'jillrhodes', 'johnsonjoshua@example.org', '$2b$12$i6.0Z/3QCAGfkWpsWWoYYOHPoxWXOVdM7a4qJeAezHIKV.xgqzDd2', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (2, 'jesseguzman', 'garzaanthony@example.org', '$2b$12$ow6/alOFQl3s90p.S4Ow4ut2sB6qbakNZDYk8VbbhjAl8bzeLqema', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (3, 'shaneramirez', 'jennifermiles@example.com', '$2b$12$AbYVOLtJzMUO6UVrdcad/OGTMCucg47lXdQsg.gHBNdGTkjyBz4oq', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (4, 'joshua35', 'blakeerik@example.com', '$2b$12$3VSOaO7gioYRwwM47mzuOOzSszwhFf43tb5Ocrqj3zYcHjj3/Qxoi', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (5, 'lindsay78', 'daviscolin@example.com', '$2b$12$uI7mBYYixZdWGCGJTTh0durKlwBb9XkZqz/NLRYk0R6UBL9gJFQgq', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (6, 'maria95', 'dudleynicholas@example.net', '$2b$12$IscAeF6ncJX1tYa85bRVTe4OwEehMQ3XTjpK6OuIU8MlIjE6qwgFG', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (7, 'tracie31', 'janetwilliams@example.org', '$2b$12$gMb46n5HeIbzQrtLdv388eidVWBvzsrFStUwPaeICQ9cmr5ce9TqK', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (8, 'mitchellclark', 'oramirez@example.com', '$2b$12$p/sUY/hGB6BUSwxDF2laveZauHOVgWKF7rfKhWND6w2GVNGJ8SjmK', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (9, 'amandasanchez', 'jacqueline19@example.net', '$2b$12$QCOIXLNEn.Twh3BKrD60OuJJrTdiK/2BnhsR0UDoGkRmHHTNZYXfq', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (10, 'gabriellecameron', 'ogray@example.net', '$2b$12$NRG2XxOjcarxQ7olRCXBjOWWuXLe0cInz4WEgoJvtZbZ0IV6DpQfi', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (11, 'nadams', 'perezantonio@example.com', '$2b$12$aiRWNrC7TiNEA/a5xlOYMuZ1aS0v5MjBnopHSDkk26N.nKdXLSSsC', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (12, 'ithomas', 'jason76@example.net', '$2b$12$zgN76x9uhUl/HPIkElU9DeJ5zwUKNvgBg.5mQMDzRr/SvS6AuDv2a', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (13, 'zhurst', 'julieryan@example.net', '$2b$12$NZQck.P/a4Dl2GW6W/DL7uX9D2HVyCVqOl2.iTnj12Q6SAjjGNCGS', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (14, 'camposmichelle', 'jeffrey28@example.com', '$2b$12$ZDcXYote3wBHHOJENCbG0e9hiYGndzJyhMn/aVYw2uly.483YrNS.', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (15, 'cruzcaitlin', 'courtneyconner@example.com', '$2b$12$/aHjFK9UNPyl/Dqo7TkAYePSwpZfIeZuVqkh3taHa3U7Jj/uxOV/C', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (16, 'maldonadoamanda', 'jrice@example.org', '$2b$12$KRh8oNK3v0jtMPBUWHT2PufnU5YFAby3HD0dfmuJbuT90d8z.rn1.', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (17, 'amoore', 'kayla51@example.com', '$2b$12$r7ge0G.sHTLwSNJJH9YsHuO58dvmLabnU3Y5W2MY4NDKMdX6U1vhS', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (18, 'meagan89', 'teresa28@example.org', '$2b$12$KYpBsO.YUoBlVH/hQ6peCeGuhJPvZcBFf3Pk70UtT1EtpimfN3egy', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (19, 'georgetracy', 'ericfarmer@example.net', '$2b$12$Xw13LiAcuhYc/wp0o3yIzu1FfXS22fA78bWgDAWOYqWdsho2vAkyK', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (20, 'brianhumphrey', 'hickmannatasha@example.com', '$2b$12$VqLAI9LielwpeGV7uL2vFueSU0Hwv2uel9n4mvdqHxUCmBHKjEfFG', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (21, 'davidalvarez', 'millertodd@example.org', '$2b$12$TTDQC0Wl3w0jLdPeQRNF.epZA5masF78oc.WO38Qc3E4F6FQ.o9oe', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (22, 'sarahcampos', 'josephbrennan@example.com', '$2b$12$U879aDNdLUuJ9dNihLHXiu1bXGRJylviRGZyws.npLLn.dAuGc1P.', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (23, 'samuel87', 'jenniferross@example.net', '$2b$12$v9j9rp02skdMn9qOdI3Ik.v7PoEI5ScVH95zJErF8ydMpFncW8KFe', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (24, 'briannasmith', 'wrightcaleb@example.org', '$2b$12$591Ml6z89ueAbb4UuNLosecLZjF2X5N5TXsfTDtPC6HI4uVbkoN3q', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (25, 'palmerjoshua', 'perezrebecca@example.com', '$2b$12$3DkiwEsux3LdsgSYBZ1GW.v.fGktTumoXJ6E/uAtLXalhZtpuVACK', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (26, 'esanchez', 'ilewis@example.net', '$2b$12$2ycv2tqvYzt4wT1EbvtBcuMu0H9WHRvAK6eTh6Qc1l.zDfhroOvpm', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (27, 'agomez', 'glee@example.net', '$2b$12$bINOCBWOALQSiLoulhPRneo6gjoD42aacxrUqackSdolovXz2e7Ou', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (28, 'brownjessica', 'dshields@example.net', '$2b$12$zjtG5qzWACpTvK6kR/khk..J7pij.fvBlHCmOg3b/3a.mZ9QKfLmy', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (29, 'robertramirez', 'wrightjames@example.com', '$2b$12$Rn/Z8/a9cOS7PJvrpoSrC.lNObUnxbrQhPSp49xzu9FCrzWzRWDLm', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (30, 'williamsyvette', 'nancyjones@example.net', '$2b$12$Tz7c1sQr9irNTXP/CASx1.9Kbe3wEhJc7PMwPyc03lw8JIvanpQRy', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (31, 'richardolson', 'novaksara@example.org', '$2b$12$HfYdreWxt7iAlyMLmGLQWu04dIImQG/O.Y86RxkHUGgHLfYm3jSce', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (32, 'gallowayjoseph', 'kbarrera@example.com', '$2b$12$0LspjAUfvW66q1YaJ1KMo.kLjm0IdVbNqGte5mBVfMSXF9Zp2OTfe', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (33, 'smoore', 'smitchell@example.net', '$2b$12$4JdYU3xdCoWFzqLokmBBEOuCyw3TFmDwITYnafxjeHLLJVlVGWPOu', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (34, 'adkinsbrian', 'tanyariley@example.net', '$2b$12$659MMMqcIaSY.uyyYMttiOPkNKu1VrJOhM/k.eLCaeCN/Sy/8mnSK', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (35, 'yuchristopher', 'hshaw@example.org', '$2b$12$ga.HGn45l55QXL2JqoMN6.oDMfrHeW3y6I6SM0jsNoWz0UthiNO02', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (36, 'kwilson', 'caseyjones@example.org', '$2b$12$DAQIm.Ox71pbIFkhyWEnWO0pRgCMAmLLtoH0iXa5J.V.lx1OgufhC', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (37, 'ksandoval', 'bethwilliams@example.org', '$2b$12$aEYw608p8w3AUWDZB.ba8O7ERFHGATbLnxria/G2SGUVUuliIbZgK', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (38, 'randy47', 'sarah35@example.org', '$2b$12$7nH02DU.oKr8m9GiJxHnlONCoJau9tR/Mj37DTZichbV4fX4qr3Fa', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (39, 'jonesjason', 'sarah10@example.com', '$2b$12$TfzX398gS7S.bfR6jN.U2.qFVfPFqL3wqJuqEJBWrkMhjxYVarRHC', TRUE, NOW(), NOW());
INSERT INTO users (user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES (40, 'justin78', 'david51@example.org', '$2b$12$AAkhF5wq6coEnupxcrWa1.3SvroBA/b6wtSAFKH2gbiFw8pA.RNgu', TRUE, NOW(), NOW());
SELECT setval(pg_get_serial_sequence('users', 'user_id'), 40, true);

-- ============================================================
-- INTERESTS  (skipped if already seeded by schema)
-- ============================================================
INSERT INTO interests (interest_id, name, category) VALUES (1, 'Hiking', 'outdoors') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (2, 'Photography', 'arts') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (3, 'Gaming', 'tech') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (4, 'Cooking', 'food') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (5, 'Traveling', 'travel') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (6, 'Music', 'arts') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (7, 'Reading', 'education') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (8, 'Fitness', 'sports') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (9, 'Dancing', 'arts') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (10, 'Movies', 'entertainment') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (11, 'Coffee', 'food') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (12, 'Yoga', 'wellness') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (13, 'Painting', 'arts') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (14, 'Cycling', 'sports') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (15, 'Swimming', 'sports') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (16, 'Volunteering', 'social') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (17, 'Technology', 'tech') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (18, 'Fashion', 'lifestyle') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (19, 'Gardening', 'outdoors') ON CONFLICT (name) DO NOTHING;
INSERT INTO interests (interest_id, name, category) VALUES (20, 'Board Games', 'entertainment') ON CONFLICT (name) DO NOTHING;
SELECT setval(pg_get_serial_sequence('interests', 'interest_id'), 20, true);

-- ============================================================
-- PROFILES
-- ============================================================
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (1, 1, 'Michael', 'Carr', '2007-03-15', 'male', 'Hey, I''m Michael! I work as a fitness trainer and love spending my free time gardening and cycling. Looking for someone genuine.', NULL, 'Mandeville', 'Jamaica', 18.015589, -77.539646, 'male', 18, 23, 20, 'Fitness Trainer', 'bachelors', 'casual', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (2, 2, 'Martha', 'Smith', '1994-03-19', 'other', 'Hey, I''m Martha! I work as a designer and love spending my free time coffee and dancing. Looking for someone genuine.', NULL, 'Savanna-la-Mar', 'Jamaica', 18.225627, -78.102357, 'female', 29, 35, 10, 'Designer', 'masters', 'friendship', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (3, 3, 'Justin', 'Huynh', '1978-06-15', 'male', 'Fitness Trainer by day, board games enthusiast by night. I''m Justin — let''s grab a coffee and see where things go.', NULL, 'Linstead', 'Jamaica', 18.095783, -76.99107, 'female', 43, 51, 10, 'Fitness Trainer', 'bachelors', 'casual', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (4, 4, 'Teresa', 'Taylor', '1978-06-19', 'non-binary', 'Lover of music and fashion. Doctor with a creative side. Let''s explore Kingston together!', NULL, 'May Pen', 'Jamaica', 17.930165, -77.259173, 'male', 40, 54, 30, 'Doctor', 'high_school', 'serious', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (5, 5, 'Stacy', 'Newton', '1982-07-05', 'non-binary', 'Lover of painting and swimming. Artist with a creative side. Let''s explore Kingston together!', NULL, 'Mandeville', 'Jamaica', 17.997719, -77.462286, 'any', 35, 51, 30, 'Artist', 'other', 'marriage', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (6, 6, 'Denise', 'Jacobs', '1994-02-08', 'non-binary', 'Just a nurse trying to find someone who loves music as much as I do. Ask me anything — I don''t bite.', NULL, 'Portmore', 'Jamaica', 17.950953, -76.924209, 'any', 29, 35, 50, 'Nurse', 'other', 'friendship', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (7, 7, 'Grant', 'Watts', '1991-04-02', 'male', 'Lover of technology and music. Software Engineer with a creative side. Let''s explore Kingston together!', NULL, 'May Pen', 'Jamaica', 17.925055, -77.251223, 'any', 25, 45, 20, 'Software Engineer', 'bachelors', 'friendship', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (8, 8, 'Dennis', 'Freeman', '1988-04-21', 'male', 'Hey, I''m Dennis! I work as a chef and love spending my free time fitness and gardening. Looking for someone genuine.', NULL, 'Savanna-la-Mar', 'Jamaica', 18.168648, -78.09039, 'any', 31, 45, 50, 'Chef', 'high_school', 'serious', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (9, 9, 'Susan', 'Williams', '1998-01-07', 'other', 'Lover of movies and painting. Fitness Trainer with a creative side. Let''s explore Kingston together!', NULL, 'Mandeville', 'Jamaica', 18.043867, -77.492941, 'female', 22, 34, 10, 'Fitness Trainer', 'bachelors', 'serious', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (10, 10, 'Jessica', 'Hill', '2006-05-07', 'non-binary', 'I''m a passionate doctor who enjoys fitness, gaming, and photography. Life''s too short for boring conversations!', NULL, 'Half Way Tree', 'Jamaica', 18.017392, -76.788156, 'male', 18, 23, 100, 'Doctor', 'bachelors', 'friendship', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (11, 11, 'Felicia', 'Anderson', '1999-08-15', 'female', 'Just a journalist trying to find someone who loves cooking as much as I do. Ask me anything — I don''t bite.', NULL, 'Half Way Tree', 'Jamaica', 18.019621, -76.8227, 'female', 18, 36, 50, 'Journalist', 'high_school', 'casual', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (12, 12, 'Candice', 'Ramos', '1987-02-04', 'other', 'Lover of music and dancing. Lawyer with a creative side. Let''s explore Kingston together!', NULL, 'Montego Bay', 'Jamaica', 18.451066, -77.924879, 'male', 29, 49, 10, 'Lawyer', 'other', 'casual', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (13, 13, 'Jessica', 'Smith', '1997-06-04', 'female', 'Just a teacher trying to find someone who loves painting as much as I do. Ask me anything — I don''t bite.', NULL, 'Old Harbour', 'Jamaica', 17.936264, -77.135325, 'female', 19, 37, 50, 'Teacher', 'other', 'marriage', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (14, 14, 'Theresa', 'Vazquez', '1989-07-02', 'female', 'Lover of photography and gardening. Accountant with a creative side. Let''s explore Kingston together!', NULL, 'Spanish Town', 'Jamaica', 18.038171, -76.948782, 'any', 33, 39, 20, 'Accountant', 'high_school', 'casual', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (15, 15, 'Joshua', 'Davenport', '2003-12-18', 'male', 'Pharmacist by day, photography enthusiast by night. I''m Joshua — let''s grab a coffee and see where things go.', NULL, 'Spanish Town', 'Jamaica', 17.981678, -76.91254, 'any', 18, 28, 30, 'Pharmacist', 'bachelors', 'friendship', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (16, 16, 'Kristen', 'Jordan', '1988-05-22', 'female', 'I''m a passionate software engineer who enjoys board games, gardening, and cooking. Life''s too short for boring conversations!', NULL, 'Savanna-la-Mar', 'Jamaica', 18.198318, -78.108114, 'male', 33, 41, 30, 'Software Engineer', 'high_school', 'serious', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (17, 17, 'Elizabeth', 'Nolan', '1998-03-11', 'non-binary', 'Lover of cooking and traveling. Fitness Trainer with a creative side. Let''s explore Kingston together!', NULL, 'Savanna-la-Mar', 'Jamaica', 18.250074, -78.112946, 'male', 25, 31, 30, 'Fitness Trainer', 'masters', 'serious', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (18, 18, 'Valerie', 'Williams', '1991-09-21', 'female', 'I''m a passionate doctor who enjoys dancing, photography, and hiking. Life''s too short for boring conversations!', NULL, 'Linstead', 'Jamaica', 18.132153, -76.992766, 'male', 31, 37, 50, 'Doctor', 'other', 'marriage', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (19, 19, 'Daniel', 'Wright', '2003-06-14', 'male', 'I''m a passionate journalist who enjoys photography, movies, and yoga. Life''s too short for boring conversations!', NULL, 'Portmore', 'Jamaica', 17.954559, -76.84984, 'male', 18, 27, 20, 'Journalist', 'high_school', 'friendship', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (20, 20, 'Heather', 'Castro', '1993-04-10', 'female', 'Software Engineer by day, coffee enthusiast by night. I''m Heather — let''s grab a coffee and see where things go.', NULL, 'Portmore', 'Jamaica', 17.997621, -76.852223, 'any', 24, 42, 10, 'Software Engineer', 'phd', 'casual', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (21, 21, 'Jennifer', 'Oliver', '1995-07-05', 'female', 'I''m a passionate chef who enjoys reading, painting, and coffee. Life''s too short for boring conversations!', NULL, 'Savanna-la-Mar', 'Jamaica', 18.201666, -78.101246, 'male', 24, 36, 30, 'Chef', 'masters', 'marriage', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (22, 22, 'Timothy', 'Young', '2000-07-08', 'male', 'I''m a passionate teacher who enjoys board games, cycling, and yoga. Life''s too short for boring conversations!', NULL, 'Mandeville', 'Jamaica', 18.008957, -77.457347, 'female', 18, 32, 100, 'Teacher', 'other', 'casual', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (23, 23, 'Vanessa', 'Cochran', '1992-04-12', 'female', 'I''m a passionate photographer who enjoys gaming, coffee, and gardening. Life''s too short for boring conversations!', NULL, 'Kingston', 'Jamaica', 18.017879, -76.843431, 'any', 28, 40, 50, 'Photographer', 'masters', 'marriage', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (24, 24, 'Jennifer', 'White', '1996-04-29', 'female', 'Just a writer trying to find someone who loves movies as much as I do. Ask me anything — I don''t bite.', NULL, 'Old Harbour', 'Jamaica', 17.954193, -77.118785, 'any', 25, 35, 100, 'Writer', 'masters', 'marriage', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (25, 25, 'Evelyn', 'Galvan', '1995-03-13', 'other', 'Doctor by day, technology enthusiast by night. I''m Evelyn — let''s grab a coffee and see where things go.', NULL, 'Linstead', 'Jamaica', 18.130619, -76.993182, 'male', 26, 36, 20, 'Doctor', 'high_school', 'casual', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (26, 26, 'Meagan', 'Moss', '2003-08-10', 'other', 'Just a musician trying to find someone who loves painting as much as I do. Ask me anything — I don''t bite.', NULL, 'Savanna-la-Mar', 'Jamaica', 18.208144, -78.120323, 'male', 18, 28, 20, 'Musician', 'other', 'marriage', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (27, 27, 'Debra', 'Cobb', '2000-06-16', 'female', 'Just a architect trying to find someone who loves technology as much as I do. Ask me anything — I don''t bite.', NULL, 'Savanna-la-Mar', 'Jamaica', 18.180034, -78.136836, 'female', 18, 33, 30, 'Architect', 'bachelors', 'friendship', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (28, 28, 'Janet', 'Williams', '1990-11-04', 'female', 'Just a accountant trying to find someone who loves fashion as much as I do. Ask me anything — I don''t bite.', NULL, 'Savanna-la-Mar', 'Jamaica', 18.174448, -78.154727, 'any', 28, 42, 20, 'Accountant', 'bachelors', 'casual', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (29, 29, 'Courtney', 'Velasquez', '1986-10-31', 'other', 'Just a musician trying to find someone who loves hiking as much as I do. Ask me anything — I don''t bite.', NULL, 'Linstead', 'Jamaica', 18.129892, -77.077073, 'female', 30, 48, 100, 'Musician', 'other', 'serious', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (30, 30, 'Hannah', 'Hoover', '1991-04-09', 'female', 'Just a designer trying to find someone who loves traveling as much as I do. Ask me anything — I don''t bite.', NULL, 'Old Harbour', 'Jamaica', 17.936264, -77.117814, 'male', 26, 44, 50, 'Designer', 'bachelors', 'casual', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (31, 31, 'Crystal', 'Johnson', '1987-07-20', 'other', 'Entrepreneur by day, dancing enthusiast by night. I''m Crystal — let''s grab a coffee and see where things go.', NULL, 'Spanish Town', 'Jamaica', 17.98677, -76.97295, 'any', 29, 47, 10, 'Entrepreneur', 'high_school', 'casual', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (32, 32, 'Jennifer', 'Ramirez', '2006-06-01', 'female', 'Lover of swimming and dancing. Pharmacist with a creative side. Let''s explore Kingston together!', NULL, 'Half Way Tree', 'Jamaica', 17.977238, -76.834378, 'any', 18, 23, 10, 'Pharmacist', 'bachelors', 'friendship', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (33, 33, 'Walter', 'Ramirez', '1989-01-10', 'male', 'I''m a passionate artist who enjoys gardening, fitness, and cooking. Life''s too short for boring conversations!', NULL, 'Half Way Tree', 'Jamaica', 18.029735, -76.751183, 'any', 28, 46, 100, 'Artist', 'high_school', 'casual', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (34, 34, 'Katrina', 'Frazier', '1985-03-29', 'other', 'Data Scientist by day, cycling enthusiast by night. I''m Katrina — let''s grab a coffee and see where things go.', NULL, 'Montego Bay', 'Jamaica', 18.476796, -77.909777, 'female', 32, 50, 20, 'Data Scientist', 'other', 'friendship', FALSE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (35, 35, 'Kimberly', 'Crosby', '1980-06-19', 'other', 'I''m a passionate entrepreneur who enjoys fitness, swimming, and painting. Life''s too short for boring conversations!', NULL, 'Half Way Tree', 'Jamaica', 17.98884, -76.761829, 'male', 41, 49, 50, 'Entrepreneur', 'bachelors', 'friendship', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (36, 36, 'Sherri', 'Green', '1990-12-17', 'non-binary', 'Lover of gaming and fitness. Marketing Manager with a creative side. Let''s explore Kingston together!', NULL, 'Half Way Tree', 'Jamaica', 18.032118, -76.819373, 'male', 32, 38, 50, 'Marketing Manager', 'phd', 'marriage', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (37, 37, 'Victor', 'Baker', '1989-06-17', 'male', 'I''m a passionate data scientist who enjoys technology, yoga, and cycling. Life''s too short for boring conversations!', NULL, 'Spanish Town', 'Jamaica', 17.98174, -76.982369, 'female', 28, 44, 30, 'Data Scientist', 'bachelors', 'casual', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (38, 38, 'Linda', 'Reed', '2001-03-07', 'non-binary', 'Artist by day, dancing enthusiast by night. I''m Linda — let''s grab a coffee and see where things go.', NULL, 'Linstead', 'Jamaica', 18.178388, -77.014284, 'female', 19, 31, 20, 'Artist', 'masters', 'serious', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (39, 39, 'Erik', 'Obrien', '1999-11-20', 'male', 'I''m a passionate lawyer who enjoys cooking, hiking, and movies. Life''s too short for boring conversations!', NULL, 'Mandeville', 'Jamaica', 17.995652, -77.548147, 'male', 19, 33, 10, 'Lawyer', 'masters', 'marriage', TRUE);
INSERT INTO profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, profile_photo_url, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible) VALUES (40, 40, 'Brian', 'Lam', '1982-07-18', 'male', 'Hey, I''m Brian! I work as a lawyer and love spending my free time gardening and movies. Looking for someone genuine.', NULL, 'Savanna-la-Mar', 'Jamaica', 18.174108, -78.120355, 'any', 40, 46, 50, 'Lawyer', 'other', 'serious', FALSE);
SELECT setval(pg_get_serial_sequence('profiles', 'profile_id'), 40, true);

-- ============================================================
-- USER_INTERESTS
-- ============================================================
INSERT INTO user_interests (user_id, interest_id) VALUES (1, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (1, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (1, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (2, 11) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (2, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (2, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (2, 7) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (2, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (2, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (3, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (3, 12) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (3, 7) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (3, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (3, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (4, 6) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (4, 18) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (4, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (4, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (4, 15) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (4, 7) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (4, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (5, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (5, 15) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (5, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (5, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (5, 18) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (5, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (6, 6) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (6, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (6, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (6, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (7, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (7, 6) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (7, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (7, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (7, 10) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (8, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (8, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (8, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (9, 10) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (9, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (9, 12) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (9, 15) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (10, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (10, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (10, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (11, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (11, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (11, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (11, 12) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (12, 6) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (12, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (12, 15) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (12, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (12, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (12, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (13, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (13, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (13, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (13, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (14, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (14, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (14, 16) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (15, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (15, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (15, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (15, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (15, 11) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (15, 15) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (15, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (16, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (16, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (16, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (16, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (16, 7) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (16, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (17, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (17, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (17, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (17, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (17, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (18, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (18, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (18, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (18, 11) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (18, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (18, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (19, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (19, 10) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (19, 12) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (19, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (20, 11) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (20, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (20, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (20, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (21, 7) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (21, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (21, 11) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (22, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (22, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (22, 12) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (23, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (23, 11) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (23, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (23, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (23, 10) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (23, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (24, 10) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (24, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (24, 18) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (24, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (24, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (24, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (24, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (25, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (25, 11) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (25, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (25, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (25, 10) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (26, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (26, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (26, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (26, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (26, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (26, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (27, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (27, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (27, 18) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (27, 15) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (27, 6) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (27, 12) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (27, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (28, 18) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (28, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (28, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (28, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (28, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (29, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (29, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (29, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (29, 16) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (29, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (29, 6) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (29, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (30, 5) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (30, 18) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (30, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (30, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (30, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (30, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (31, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (31, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (31, 16) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (31, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (31, 2) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (31, 6) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (32, 15) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (32, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (32, 12) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (32, 6) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (33, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (33, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (33, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (34, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (34, 12) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (34, 15) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (35, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (35, 15) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (35, 13) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (35, 11) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (35, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (35, 20) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (36, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (36, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (36, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (36, 16) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (37, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (37, 12) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (37, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (37, 11) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (37, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (37, 16) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (37, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (38, 9) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (38, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (38, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (38, 10) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (38, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (38, 14) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (39, 4) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (39, 1) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (39, 10) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (39, 16) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (39, 17) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (39, 8) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (40, 19) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (40, 10) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (40, 3) ON CONFLICT DO NOTHING;
INSERT INTO user_interests (user_id, interest_id) VALUES (40, 8) ON CONFLICT DO NOTHING;

-- ============================================================
-- SWIPES
-- ============================================================
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (1, 1, 6, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (2, 1, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (3, 1, 9, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (4, 1, 10, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (5, 1, 11, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (6, 1, 13, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (7, 1, 16, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (8, 1, 17, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (9, 1, 31, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (10, 1, 38, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (11, 2, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (12, 2, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (13, 2, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (14, 2, 16, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (15, 2, 19, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (16, 2, 25, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (17, 2, 27, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (18, 2, 28, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (19, 2, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (20, 2, 33, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (21, 2, 36, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (22, 2, 38, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (23, 3, 4, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (24, 3, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (25, 3, 8, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (26, 3, 11, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (27, 3, 13, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (28, 3, 15, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (29, 3, 19, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (30, 3, 21, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (31, 3, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (32, 3, 27, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (33, 3, 28, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (34, 3, 29, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (35, 3, 30, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (36, 3, 37, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (37, 4, 2, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (38, 4, 3, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (39, 4, 5, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (40, 4, 13, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (41, 4, 15, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (42, 4, 23, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (43, 4, 25, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (44, 4, 32, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (45, 4, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (46, 4, 35, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (47, 4, 39, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (48, 5, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (49, 5, 4, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (50, 5, 7, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (51, 5, 10, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (52, 5, 16, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (53, 5, 21, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (54, 5, 22, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (55, 5, 25, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (56, 5, 28, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (57, 5, 30, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (58, 5, 34, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (59, 5, 35, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (60, 6, 4, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (61, 6, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (62, 6, 15, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (63, 6, 16, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (64, 6, 18, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (65, 6, 19, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (66, 6, 20, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (67, 6, 25, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (68, 6, 26, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (69, 6, 28, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (70, 6, 31, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (71, 6, 39, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (72, 6, 40, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (73, 7, 6, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (74, 7, 11, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (75, 7, 12, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (76, 7, 17, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (77, 7, 19, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (78, 7, 20, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (79, 7, 22, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (80, 7, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (81, 7, 35, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (82, 7, 38, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (83, 8, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (84, 8, 6, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (85, 8, 10, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (86, 8, 11, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (87, 8, 13, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (88, 8, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (89, 8, 16, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (90, 8, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (91, 8, 23, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (92, 8, 24, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (93, 8, 26, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (94, 8, 27, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (95, 8, 28, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (96, 8, 34, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (97, 8, 35, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (98, 8, 36, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (99, 8, 37, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (100, 8, 38, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (101, 9, 1, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (102, 9, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (103, 9, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (104, 9, 4, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (105, 9, 11, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (106, 9, 13, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (107, 9, 18, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (108, 9, 24, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (109, 9, 27, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (110, 9, 28, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (111, 9, 29, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (112, 9, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (113, 9, 35, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (114, 10, 1, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (115, 10, 5, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (116, 10, 6, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (117, 10, 9, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (118, 10, 18, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (119, 10, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (120, 10, 21, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (121, 10, 23, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (122, 10, 26, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (123, 10, 27, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (124, 10, 28, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (125, 10, 30, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (126, 10, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (127, 10, 35, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (128, 10, 36, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (129, 10, 37, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (130, 10, 40, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (131, 11, 1, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (132, 11, 2, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (133, 11, 5, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (134, 11, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (135, 11, 8, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (136, 11, 12, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (137, 11, 13, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (138, 11, 14, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (139, 11, 16, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (140, 11, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (141, 11, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (142, 11, 27, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (143, 11, 29, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (144, 11, 34, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (145, 11, 38, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (146, 11, 39, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (147, 11, 40, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (148, 12, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (149, 12, 6, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (150, 12, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (151, 12, 8, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (152, 12, 11, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (153, 12, 20, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (154, 12, 21, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (155, 12, 27, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (156, 12, 29, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (157, 12, 30, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (158, 12, 40, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (159, 13, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (160, 13, 8, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (161, 13, 18, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (162, 13, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (163, 13, 22, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (164, 13, 24, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (165, 13, 27, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (166, 13, 28, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (167, 13, 29, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (168, 13, 31, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (169, 14, 1, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (170, 14, 2, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (171, 14, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (172, 14, 4, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (173, 14, 6, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (174, 14, 9, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (175, 14, 13, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (176, 14, 18, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (177, 14, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (178, 14, 21, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (179, 14, 25, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (180, 14, 26, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (181, 14, 28, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (182, 14, 31, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (183, 14, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (184, 14, 36, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (185, 14, 37, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (186, 14, 40, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (187, 15, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (188, 15, 3, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (189, 15, 4, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (190, 15, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (191, 15, 13, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (192, 15, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (193, 15, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (194, 15, 27, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (195, 15, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (196, 15, 33, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (197, 15, 34, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (198, 15, 37, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (199, 15, 39, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (200, 16, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (201, 16, 4, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (202, 16, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (203, 16, 12, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (204, 16, 13, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (205, 16, 15, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (206, 16, 18, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (207, 16, 23, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (208, 16, 25, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (209, 16, 30, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (210, 16, 31, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (211, 16, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (212, 16, 33, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (213, 16, 35, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (214, 16, 39, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (215, 16, 40, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (216, 17, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (217, 17, 8, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (218, 17, 15, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (219, 17, 18, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (220, 17, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (221, 17, 20, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (222, 17, 21, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (223, 17, 23, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (224, 17, 25, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (225, 17, 30, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (226, 17, 35, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (227, 17, 38, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (228, 18, 12, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (229, 18, 13, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (230, 18, 17, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (231, 18, 20, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (232, 18, 21, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (233, 18, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (234, 18, 27, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (235, 18, 31, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (236, 18, 38, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (237, 18, 40, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (238, 19, 1, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (239, 19, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (240, 19, 6, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (241, 19, 12, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (242, 19, 16, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (243, 19, 18, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (244, 19, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (245, 19, 24, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (246, 19, 25, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (247, 19, 26, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (248, 19, 29, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (249, 19, 30, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (250, 19, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (251, 19, 35, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (252, 20, 1, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (253, 20, 4, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (254, 20, 10, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (255, 20, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (256, 20, 16, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (257, 20, 18, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (258, 20, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (259, 20, 24, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (260, 20, 26, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (261, 20, 28, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (262, 20, 29, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (263, 20, 30, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (264, 20, 38, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (265, 21, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (266, 21, 3, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (267, 21, 6, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (268, 21, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (269, 21, 22, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (270, 21, 23, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (271, 21, 26, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (272, 21, 28, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (273, 21, 31, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (274, 21, 33, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (275, 21, 35, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (276, 21, 36, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (277, 21, 39, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (278, 21, 40, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (279, 22, 1, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (280, 22, 4, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (281, 22, 10, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (282, 22, 17, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (283, 22, 18, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (284, 22, 23, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (285, 22, 27, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (286, 22, 29, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (287, 22, 33, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (288, 22, 38, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (289, 23, 12, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (290, 23, 13, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (291, 23, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (292, 23, 15, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (293, 23, 25, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (294, 23, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (295, 23, 34, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (296, 23, 37, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (297, 23, 38, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (298, 23, 40, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (299, 24, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (300, 24, 6, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (301, 24, 7, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (302, 24, 8, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (303, 24, 9, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (304, 24, 11, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (305, 24, 13, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (306, 24, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (307, 24, 16, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (308, 24, 17, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (309, 24, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (310, 24, 21, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (311, 24, 23, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (312, 24, 26, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (313, 24, 29, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (314, 24, 36, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (315, 24, 37, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (316, 24, 40, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (317, 25, 4, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (318, 25, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (319, 25, 8, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (320, 25, 11, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (321, 25, 12, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (322, 25, 14, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (323, 25, 15, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (324, 25, 17, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (325, 25, 19, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (326, 25, 28, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (327, 26, 6, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (328, 26, 8, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (329, 26, 9, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (330, 26, 17, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (331, 26, 20, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (332, 26, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (333, 26, 28, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (334, 26, 31, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (335, 26, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (336, 27, 9, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (337, 27, 12, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (338, 27, 20, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (339, 27, 21, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (340, 27, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (341, 27, 23, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (342, 27, 28, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (343, 27, 29, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (344, 27, 33, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (345, 27, 35, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (346, 27, 38, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (347, 27, 39, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (348, 27, 40, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (349, 28, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (350, 28, 7, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (351, 28, 18, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (352, 28, 20, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (353, 28, 24, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (354, 28, 31, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (355, 28, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (356, 28, 36, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (357, 28, 37, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (358, 29, 1, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (359, 29, 6, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (360, 29, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (361, 29, 9, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (362, 29, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (363, 29, 19, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (364, 29, 25, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (365, 29, 30, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (366, 29, 31, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (367, 29, 35, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (368, 29, 36, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (369, 30, 1, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (370, 30, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (371, 30, 6, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (372, 30, 11, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (373, 30, 13, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (374, 30, 17, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (375, 30, 18, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (376, 30, 20, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (377, 30, 23, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (378, 30, 25, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (379, 30, 28, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (380, 30, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (381, 30, 36, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (382, 30, 39, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (383, 30, 40, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (384, 31, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (385, 31, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (386, 31, 7, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (387, 31, 12, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (388, 31, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (389, 31, 17, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (390, 31, 19, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (391, 31, 21, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (392, 31, 23, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (393, 31, 24, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (394, 31, 29, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (395, 31, 40, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (396, 32, 1, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (397, 32, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (398, 32, 3, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (399, 32, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (400, 32, 10, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (401, 32, 15, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (402, 32, 16, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (403, 32, 18, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (404, 32, 21, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (405, 32, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (406, 32, 23, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (407, 32, 26, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (408, 32, 27, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (409, 32, 30, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (410, 32, 33, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (411, 32, 36, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (412, 32, 38, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (413, 33, 2, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (414, 33, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (415, 33, 4, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (416, 33, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (417, 33, 9, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (418, 33, 15, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (419, 33, 17, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (420, 33, 25, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (421, 33, 27, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (422, 33, 28, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (423, 33, 30, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (424, 33, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (425, 33, 37, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (426, 33, 38, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (427, 33, 39, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (428, 33, 40, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (429, 34, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (430, 34, 4, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (431, 34, 6, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (432, 34, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (433, 34, 10, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (434, 34, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (435, 34, 26, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (436, 34, 28, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (437, 34, 29, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (438, 34, 30, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (439, 34, 35, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (440, 34, 40, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (441, 35, 2, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (442, 35, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (443, 35, 4, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (444, 35, 6, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (445, 35, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (446, 35, 10, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (447, 35, 11, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (448, 35, 12, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (449, 35, 15, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (450, 35, 18, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (451, 35, 20, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (452, 35, 22, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (453, 35, 28, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (454, 35, 29, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (455, 35, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (456, 35, 36, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (457, 36, 2, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (458, 36, 6, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (459, 36, 9, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (460, 36, 10, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (461, 36, 12, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (462, 36, 14, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (463, 36, 20, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (464, 36, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (465, 36, 28, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (466, 36, 37, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (467, 36, 39, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (468, 36, 40, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (469, 37, 1, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (470, 37, 7, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (471, 37, 11, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (472, 37, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (473, 37, 15, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (474, 37, 17, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (475, 37, 21, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (476, 37, 33, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (477, 37, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (478, 37, 40, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (479, 38, 4, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (480, 38, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (481, 38, 11, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (482, 38, 13, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (483, 38, 23, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (484, 38, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (485, 38, 33, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (486, 38, 34, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (487, 38, 39, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (488, 38, 40, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (489, 39, 2, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (490, 39, 3, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (491, 39, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (492, 39, 6, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (493, 39, 7, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (494, 39, 10, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (495, 39, 14, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (496, 39, 15, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (497, 39, 16, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (498, 39, 17, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (499, 39, 18, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (500, 39, 22, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (501, 39, 23, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (502, 39, 25, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (503, 39, 27, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (504, 39, 30, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (505, 39, 31, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (506, 39, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (507, 39, 36, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (508, 39, 40, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (509, 40, 1, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (510, 40, 5, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (511, 40, 6, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (512, 40, 7, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (513, 40, 14, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (514, 40, 16, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (515, 40, 17, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (516, 40, 20, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (517, 40, 21, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (518, 40, 23, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (519, 40, 26, 'pass') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (520, 40, 29, 'dislike') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (521, 40, 32, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (522, 40, 33, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (523, 40, 34, 'like') ON CONFLICT DO NOTHING;
INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES (524, 40, 37, 'pass') ON CONFLICT DO NOTHING;
SELECT setval(pg_get_serial_sequence('swipes', 'swipe_id'), 524, true);

-- ============================================================
-- MATCHES
-- ============================================================
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (1, 17, 18) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (2, 8, 24) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (3, 10, 36) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (4, 2, 32) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (5, 3, 5) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (6, 8, 11) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (7, 34, 40) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (8, 23, 32) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (9, 7, 12) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (10, 19, 24) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (11, 16, 32) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (12, 15, 33) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (13, 1, 10) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (14, 7, 34) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (15, 5, 16) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (16, 20, 28) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (17, 27, 33) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (18, 6, 40) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (19, 17, 25) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (20, 13, 18) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (21, 29, 35) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (22, 4, 35) ON CONFLICT DO NOTHING;
INSERT INTO matches (match_id, user1_id, user2_id) VALUES (23, 34, 35) ON CONFLICT DO NOTHING;
SELECT setval(pg_get_serial_sequence('matches', 'match_id'), 23, true);

-- ============================================================
-- CONVERSATIONS
-- ============================================================
INSERT INTO conversations (conversation_id, match_id) VALUES (1, 1) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (2, 2) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (3, 3) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (4, 4) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (5, 5) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (6, 6) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (7, 7) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (8, 8) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (9, 9) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (10, 10) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (11, 11) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (12, 12) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (13, 13) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (14, 14) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (15, 15) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (16, 16) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (17, 17) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (18, 18) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (19, 19) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (20, 20) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (21, 21) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (22, 22) ON CONFLICT DO NOTHING;
INSERT INTO conversations (conversation_id, match_id) VALUES (23, 23) ON CONFLICT DO NOTHING;
SELECT setval(pg_get_serial_sequence('conversations', 'conversation_id'), 23, true);

-- ============================================================
-- MESSAGES
-- ============================================================
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (1, 1, 17, 'Same here! It''s a date then.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (2, 1, 18, 'Maybe this weekend? I''m usually free Saturday afternoons.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (3, 1, 17, 'I noticed you''re into dancing too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (4, 1, 18, 'Hi there! I saw we matched, that''s really cool :)', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (5, 2, 24, 'Probably Emancipation Park or somewhere along the waterfront.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (6, 2, 8, 'Maybe this weekend? I''m usually free Saturday afternoons.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (7, 2, 24, 'We should grab a coffee in Kingston sometime!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (8, 2, 8, 'Same here! It''s a date then.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (9, 2, 24, 'Not bad at all! Just got back from a long day. You?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (10, 2, 8, 'What''s your favourite spot in Kingston?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (11, 3, 36, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (12, 3, 10, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (13, 3, 36, 'Saturday works for me. Looking forward to it!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (14, 3, 10, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (15, 3, 36, 'Same here! It''s a date then.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (16, 3, 10, 'Hi there! I saw we matched, that''s really cool :)', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (17, 4, 32, 'I noticed you''re into volunteering too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (18, 4, 2, 'Haha yeah, technology is life honestly.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (19, 4, 32, 'Maybe this weekend? I''m usually free Saturday afternoons.', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (20, 5, 5, 'I noticed you''re into dancing too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (21, 5, 3, 'What''s your favourite spot in Kingston?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (22, 5, 5, 'Probably Emancipation Park or somewhere along the waterfront.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (23, 5, 3, 'Haha yeah, cycling is life honestly.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (24, 5, 5, 'Not bad at all! Just got back from a long day. You?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (25, 5, 3, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (26, 5, 5, 'What''s your favourite spot in Kingston?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (27, 5, 3, 'Same here! It''s a date then.', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (28, 6, 8, 'Maybe this weekend? I''m usually free Saturday afternoons.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (29, 6, 11, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (30, 6, 8, 'Oh nice, I love it there! Very chill vibes.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (31, 6, 11, 'I noticed you''re into yoga too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (32, 6, 8, 'I noticed you''re into dancing too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (33, 6, 11, 'Probably Emancipation Park or somewhere along the waterfront.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (34, 6, 8, 'Exactly! Simple things are the best.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (35, 6, 11, 'Same here! It''s a date then.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (36, 6, 8, 'Your profile really caught my eye. What do you do for fun?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (37, 6, 11, 'Hey! How''s it going?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (38, 7, 40, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (39, 7, 34, 'Haha yeah, painting is life honestly.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (40, 7, 40, 'Exactly! Simple things are the best.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (41, 7, 34, 'I noticed you''re into photography too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (42, 7, 40, 'Maybe this weekend? I''m usually free Saturday afternoons.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (43, 7, 34, 'Your profile really caught my eye. What do you do for fun?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (44, 8, 32, 'Exactly! Simple things are the best.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (45, 8, 23, 'Not bad at all! Just got back from a long day. You?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (46, 8, 32, 'Saturday works for me. Looking forward to it!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (47, 8, 23, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (48, 8, 32, 'Same here! It''s a date then.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (49, 8, 23, 'I noticed you''re into fitness too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (50, 8, 32, 'Probably Emancipation Park or somewhere along the waterfront.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (51, 8, 23, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (52, 8, 32, 'Hi there! I saw we matched, that''s really cool :)', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (53, 9, 7, 'Haha yeah, gaming is life honestly.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (54, 9, 12, 'Maybe this weekend? I''m usually free Saturday afternoons.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (55, 9, 7, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (56, 9, 12, 'Your profile really caught my eye. What do you do for fun?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (57, 9, 7, 'Saturday works for me. Looking forward to it!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (58, 9, 12, 'What''s your favourite spot in Kingston?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (59, 9, 7, 'Your profile really caught my eye. What do you do for fun?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (60, 10, 19, 'Probably Emancipation Park or somewhere along the waterfront.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (61, 10, 24, 'What''s your favourite spot in Kingston?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (62, 10, 19, 'Probably Emancipation Park or somewhere along the waterfront.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (63, 10, 24, 'I noticed you''re into hiking too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (64, 10, 19, 'Exactly! Simple things are the best.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (65, 10, 24, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (66, 10, 19, 'Maybe this weekend? I''m usually free Saturday afternoons.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (67, 10, 24, 'Same here! It''s a date then.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (68, 10, 19, 'Haha yeah, hiking is life honestly.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (69, 10, 24, 'Probably Emancipation Park or somewhere along the waterfront.', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (70, 11, 16, 'Your profile really caught my eye. What do you do for fun?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (71, 11, 32, 'Your profile really caught my eye. What do you do for fun?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (72, 11, 16, 'That sounds like a great idea! When are you free?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (73, 11, 32, 'I noticed you''re into dancing too! What got you into it?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (74, 12, 33, 'Exactly! Simple things are the best.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (75, 12, 15, 'Exactly! Simple things are the best.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (76, 12, 33, 'We should grab a coffee in Kingston sometime!', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (77, 13, 1, 'Saturday works for me. Looking forward to it!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (78, 13, 10, 'Maybe this weekend? I''m usually free Saturday afternoons.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (79, 13, 1, 'Same here! It''s a date then.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (80, 13, 10, 'Hi there! I saw we matched, that''s really cool :)', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (81, 14, 34, 'Same here! It''s a date then.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (82, 14, 7, 'Your profile really caught my eye. What do you do for fun?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (83, 14, 34, 'Not bad at all! Just got back from a long day. You?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (84, 14, 7, 'Exactly! Simple things are the best.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (85, 14, 34, 'What''s your favourite spot in Kingston?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (86, 14, 7, 'Haha yeah, swimming is life honestly.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (87, 14, 34, 'Not bad at all! Just got back from a long day. You?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (88, 14, 7, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (89, 14, 34, 'I noticed you''re into gardening too! What got you into it?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (90, 15, 16, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (91, 15, 5, 'That sounds like a great idea! When are you free?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (92, 15, 16, 'Haha yeah, cycling is life honestly.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (93, 15, 5, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (94, 15, 16, 'Haha yeah, reading is life honestly.', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (95, 16, 20, 'That sounds like a great idea! When are you free?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (96, 16, 28, 'Oh nice, I love it there! Very chill vibes.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (97, 16, 20, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (98, 16, 28, 'Probably Emancipation Park or somewhere along the waterfront.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (99, 16, 20, 'Oh nice, I love it there! Very chill vibes.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (100, 16, 28, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (101, 16, 20, 'Oh nice, I love it there! Very chill vibes.', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (102, 17, 33, 'What''s your favourite spot in Kingston?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (103, 17, 27, 'Haha yeah, painting is life honestly.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (104, 17, 33, 'Maybe this weekend? I''m usually free Saturday afternoons.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (105, 17, 27, 'Same here! It''s a date then.', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (106, 18, 6, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (107, 18, 40, 'Oh nice, I love it there! Very chill vibes.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (108, 18, 6, 'Maybe this weekend? I''m usually free Saturday afternoons.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (109, 18, 40, 'Your profile really caught my eye. What do you do for fun?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (110, 18, 6, 'That sounds like a great idea! When are you free?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (111, 19, 25, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (112, 19, 17, 'Oh nice, I love it there! Very chill vibes.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (113, 19, 25, 'I noticed you''re into reading too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (114, 19, 17, 'Oh nice, I love it there! Very chill vibes.', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (115, 20, 13, 'Saturday works for me. Looking forward to it!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (116, 20, 18, 'Not bad at all! Just got back from a long day. You?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (117, 20, 13, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (118, 20, 18, 'Your profile really caught my eye. What do you do for fun?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (119, 21, 35, 'Exactly! Simple things are the best.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (120, 21, 29, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (121, 21, 35, 'That sounds like a great idea! When are you free?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (122, 21, 29, 'I noticed you''re into gardening too! What got you into it?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (123, 22, 4, 'That sounds like a great idea! When are you free?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (124, 22, 35, 'We should grab a coffee in Kingston sometime!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (125, 22, 4, 'I noticed you''re into yoga too! What got you into it?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (126, 22, 35, 'Your profile really caught my eye. What do you do for fun?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (127, 22, 4, 'Not bad at all! Just got back from a long day. You?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (128, 22, 35, 'That sounds like a great idea! When are you free?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (129, 22, 4, 'Hey! How''s it going?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (130, 22, 35, 'Saturday works for me. Looking forward to it!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (131, 22, 4, 'Your profile really caught my eye. What do you do for fun?', FALSE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (132, 23, 34, 'Exactly! Simple things are the best.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (133, 23, 35, 'That sounds like a great idea! When are you free?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (134, 23, 34, 'Hi there! I saw we matched, that''s really cool :)', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (135, 23, 35, 'We should grab a coffee in Kingston sometime!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (136, 23, 34, 'We should grab a coffee in Kingston sometime!', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (137, 23, 35, 'Same here! It''s a date then.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (138, 23, 34, 'Your profile really caught my eye. What do you do for fun?', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (139, 23, 35, 'Probably Emancipation Park or somewhere along the waterfront.', TRUE);
INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES (140, 23, 34, 'We should grab a coffee in Kingston sometime!', FALSE);
SELECT setval(pg_get_serial_sequence('messages', 'message_id'), 140, true);

-- ============================================================
-- FAVORITES
-- ============================================================
INSERT INTO favorites (user_id, favorited_id) VALUES (25, 23) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (12, 1) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (37, 3) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (12, 16) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (15, 39) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (21, 25) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (7, 32) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (31, 35) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (19, 9) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (5, 16) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (21, 40) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (34, 31) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (32, 3) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (9, 11) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (22, 29) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (37, 33) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (15, 2) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (36, 40) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (2, 23) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (10, 22) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (40, 13) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (4, 2) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (21, 12) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (7, 22) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (23, 15) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (12, 21) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (26, 38) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (23, 21) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (34, 24) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (11, 7) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (37, 26) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (35, 4) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (10, 8) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (5, 24) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (9, 22) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (12, 39) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (32, 23) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (6, 4) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (28, 32) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (38, 12) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (18, 12) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (38, 15) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (38, 21) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (16, 18) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (32, 35) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (10, 38) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (20, 12) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (15, 37) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (20, 21) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (37, 10) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (34, 23) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (37, 13) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (4, 31) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (23, 38) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (11, 6) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (2, 18) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (2, 21) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (25, 20) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (39, 15) ON CONFLICT DO NOTHING;
INSERT INTO favorites (user_id, favorited_id) VALUES (1, 22) ON CONFLICT DO NOTHING;

-- ============================================================
-- PROFILE_PHOTOS
-- ============================================================
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (1, 1, 'https://picsum.photos/seed/1-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (2, 2, 'https://picsum.photos/seed/2-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (3, 2, 'https://picsum.photos/seed/2-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (4, 3, 'https://picsum.photos/seed/3-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (5, 4, 'https://picsum.photos/seed/4-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (6, 5, 'https://picsum.photos/seed/5-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (7, 5, 'https://picsum.photos/seed/5-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (8, 5, 'https://picsum.photos/seed/5-2/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (9, 6, 'https://picsum.photos/seed/6-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (10, 7, 'https://picsum.photos/seed/7-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (11, 7, 'https://picsum.photos/seed/7-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (12, 8, 'https://picsum.photos/seed/8-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (13, 8, 'https://picsum.photos/seed/8-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (14, 9, 'https://picsum.photos/seed/9-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (15, 10, 'https://picsum.photos/seed/10-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (16, 10, 'https://picsum.photos/seed/10-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (17, 10, 'https://picsum.photos/seed/10-2/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (18, 11, 'https://picsum.photos/seed/11-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (19, 12, 'https://picsum.photos/seed/12-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (20, 13, 'https://picsum.photos/seed/13-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (21, 13, 'https://picsum.photos/seed/13-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (22, 14, 'https://picsum.photos/seed/14-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (23, 14, 'https://picsum.photos/seed/14-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (24, 15, 'https://picsum.photos/seed/15-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (25, 15, 'https://picsum.photos/seed/15-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (26, 15, 'https://picsum.photos/seed/15-2/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (27, 16, 'https://picsum.photos/seed/16-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (28, 16, 'https://picsum.photos/seed/16-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (29, 17, 'https://picsum.photos/seed/17-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (30, 18, 'https://picsum.photos/seed/18-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (31, 18, 'https://picsum.photos/seed/18-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (32, 19, 'https://picsum.photos/seed/19-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (33, 19, 'https://picsum.photos/seed/19-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (34, 20, 'https://picsum.photos/seed/20-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (35, 20, 'https://picsum.photos/seed/20-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (36, 21, 'https://picsum.photos/seed/21-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (37, 21, 'https://picsum.photos/seed/21-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (38, 22, 'https://picsum.photos/seed/22-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (39, 22, 'https://picsum.photos/seed/22-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (40, 22, 'https://picsum.photos/seed/22-2/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (41, 23, 'https://picsum.photos/seed/23-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (42, 23, 'https://picsum.photos/seed/23-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (43, 24, 'https://picsum.photos/seed/24-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (44, 25, 'https://picsum.photos/seed/25-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (45, 25, 'https://picsum.photos/seed/25-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (46, 26, 'https://picsum.photos/seed/26-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (47, 26, 'https://picsum.photos/seed/26-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (48, 26, 'https://picsum.photos/seed/26-2/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (49, 27, 'https://picsum.photos/seed/27-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (50, 27, 'https://picsum.photos/seed/27-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (51, 27, 'https://picsum.photos/seed/27-2/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (52, 28, 'https://picsum.photos/seed/28-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (53, 28, 'https://picsum.photos/seed/28-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (54, 28, 'https://picsum.photos/seed/28-2/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (55, 29, 'https://picsum.photos/seed/29-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (56, 30, 'https://picsum.photos/seed/30-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (57, 31, 'https://picsum.photos/seed/31-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (58, 31, 'https://picsum.photos/seed/31-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (59, 32, 'https://picsum.photos/seed/32-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (60, 33, 'https://picsum.photos/seed/33-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (61, 34, 'https://picsum.photos/seed/34-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (62, 34, 'https://picsum.photos/seed/34-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (63, 35, 'https://picsum.photos/seed/35-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (64, 36, 'https://picsum.photos/seed/36-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (65, 36, 'https://picsum.photos/seed/36-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (66, 37, 'https://picsum.photos/seed/37-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (67, 37, 'https://picsum.photos/seed/37-1/400/400', FALSE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (68, 38, 'https://picsum.photos/seed/38-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (69, 39, 'https://picsum.photos/seed/39-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (70, 40, 'https://picsum.photos/seed/40-0/400/400', TRUE);
INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES (71, 40, 'https://picsum.photos/seed/40-1/400/400', FALSE);
SELECT setval(pg_get_serial_sequence('profile_photos', 'photo_id'), 71, true);


COMMIT;

-- Done! All 40 users, profiles, swipes, matches, messages imported.
