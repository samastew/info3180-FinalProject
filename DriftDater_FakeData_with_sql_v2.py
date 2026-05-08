"""
DriftDater — SQL Seed File Generator
======================================
Generates a ready-to-run DriftDater_FakeData.sql file containing:
  1. Full schema (DROP + CREATE) with corrected swipes.action as VARCHAR(10)
  2. INSERT statements for every table

No database connection required — just run the script and import the
generated SQL file directly into PostgreSQL.

Requirements:
    pip install faker bcrypt

Usage:
    python DriftDater_FakeData_with_sql.py
    psql -U postgres -d driftdater -f DriftDater_FakeData.sql

Fixes applied vs original:
  - users INSERT now includes created_at, updated_at columns (were NOT NULL,
    causing "null value in column created_at" errors)
  - swipes.action changed from PostgreSQL ENUM (swipe_action) to
    VARCHAR(10) with a CHECK constraint — compatible with SQLAlchemy String(10)
  - Schema is now embedded in the output file so a single SQL file does
    everything: drop old tables, create fresh schema, insert data
"""

import random
import bcrypt
from faker import Faker
from datetime import datetime, timezone
from pathlib import Path

# ── Settings ───────────────────────────────────────────────────────────────────
OUTPUT_FILE   = "DriftDater_FakeData.sql"
NUM_USERS     = 40
NUM_FAVORITES = 60
SWIPE_DENSITY = 0.35
MIN_INTERESTS = 3
MAX_INTERESTS = 7

fake = Faker()
Faker.seed(42)
random.seed(42)

# ── Static data ────────────────────────────────────────────────────────────────
INTEREST_NAMES = [
    "Hiking", "Photography", "Gaming", "Cooking", "Traveling",
    "Music", "Reading", "Fitness", "Dancing", "Movies", "Coffee",
    "Yoga", "Painting", "Cycling", "Swimming", "Volunteering",
    "Technology", "Fashion", "Gardening", "Board Games",
]
INTEREST_CATEGORIES = {
    "Hiking": "outdoors",       "Photography": "arts",      "Gaming": "tech",
    "Cooking": "food",          "Traveling": "travel",      "Music": "arts",
    "Reading": "education",     "Fitness": "sports",        "Dancing": "arts",
    "Movies": "entertainment",  "Coffee": "food",           "Yoga": "wellness",
    "Painting": "arts",         "Cycling": "sports",        "Swimming": "sports",
    "Volunteering": "social",   "Technology": "tech",       "Fashion": "lifestyle",
    "Gardening": "outdoors",    "Board Games": "entertainment",
}
GENDERS          = ["male", "female", "non-binary", "other"]
LOOKING_FOR      = ["male", "female", "any"]
EDUCATION_LEVELS = ["high_school", "bachelors", "masters", "phd", "other"]
REL_GOALS        = ["casual", "serious", "friendship", "marriage"]
OCCUPATIONS      = [
    "Software Engineer", "Teacher", "Doctor", "Nurse", "Lawyer",
    "Designer", "Artist", "Chef", "Entrepreneur", "Student",
    "Accountant", "Photographer", "Musician", "Journalist", "Architect",
    "Data Scientist", "Marketing Manager", "Fitness Trainer", "Pharmacist", "Writer",
]
CITIES = [
    ("Kingston",       "Jamaica", 17.9970, -76.7936),
    ("Montego Bay",    "Jamaica", 18.4762, -77.8939),
    ("Portmore",       "Jamaica", 17.9500, -76.8833),
    ("Spanish Town",   "Jamaica", 17.9913, -76.9567),
    ("Mandeville",     "Jamaica", 18.0411, -77.5036),
    ("May Pen",        "Jamaica", 17.9639, -77.2447),
    ("Old Harbour",    "Jamaica", 17.9377, -77.1067),
    ("Savanna-la-Mar", "Jamaica", 18.2167, -78.1333),
    ("Linstead",       "Jamaica", 18.1333, -77.0333),
    ("Half Way Tree",  "Jamaica", 18.0120, -76.7970),
]
MESSAGE_TEMPLATES = [
    "Hey! How's it going?",
    "Hi there! I saw we matched, that's really cool :)",
    "I noticed you're into {interest} too! What got you into it?",
    "Your profile really caught my eye. What do you do for fun?",
    "Not bad at all! Just got back from a long day. You?",
    "Haha yeah, {interest} is life honestly.",
    "We should grab a coffee in Kingston sometime!",
    "That sounds like a great idea! When are you free?",
    "Maybe this weekend? I'm usually free Saturday afternoons.",
    "Saturday works for me. Looking forward to it!",
    "Same here! It's a date then.",
    "What's your favourite spot in Kingston?",
    "Probably Emancipation Park or somewhere along the waterfront.",
    "Oh nice, I love it there! Very chill vibes.",
    "Exactly! Simple things are the best.",
]

# ── Helpers ────────────────────────────────────────────────────────────────────

def esc(value) -> str:
    """Convert a Python value to a SQL literal string."""
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (int, float)):
        return str(value)
    safe = str(value).replace("'", "''")
    return f"'{safe}'"


def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def random_dob(min_age=18, max_age=60):
    age = random.randint(min_age, max_age)
    return fake.date_of_birth(minimum_age=age, maximum_age=age)


def age_from_dob(dob) -> int:
    today = datetime.now(timezone.utc).date()
    return (today - dob).days // 365


def sensible_age_prefs(age: int):
    spread = random.randint(3, 10)
    return max(18, age - spread), min(65, age + spread)


def make_bio(first_name, occupation, interests) -> str:
    templates = [
        f"Hey, I'm {first_name}! I work as a {occupation.lower()} and love spending my free time "
        f"{interests[0].lower()} and {interests[1].lower()}. Looking for someone genuine.",
        f"{occupation} by day, {interests[0].lower()} enthusiast by night. "
        f"I'm {first_name} — let's grab a coffee and see where things go.",
        f"I'm a passionate {occupation.lower()} who enjoys {interests[0].lower()}, "
        f"{interests[1].lower()}, and {interests[2].lower()}. Life's too short for boring conversations!",
        f"Just a {occupation.lower()} trying to find someone who loves {interests[0].lower()} "
        f"as much as I do. Ask me anything — I don't bite.",
        f"Lover of {interests[0].lower()} and {interests[1].lower()}. "
        f"{occupation} with a creative side. Let's explore Kingston together!",
    ]
    return random.choice(templates)


# ── Data builders ──────────────────────────────────────────────────────────────

def build_users():
    print("  → Generating users...")
    users = []
    used_emails, used_usernames = set(), set()
    for i in range(1, NUM_USERS + 1):
        while True:
            email = fake.unique.email()
            if email not in used_emails:
                used_emails.add(email)
                break
        while True:
            username = fake.user_name()
            if username not in used_usernames:
                used_usernames.add(username)
                break
        users.append({
            "user_id":       i,
            "username":      username,
            "email":         email,
            "password_hash": hash_password("Password123!"),
            "is_active":     True,
            # FIX: always supply created_at / updated_at so NOT NULL constraint is satisfied
            "created_at":    "NOW()",
            "updated_at":    "NOW()",
        })
    print(f"     ✓ {len(users)} users")
    return users


def build_profiles_and_interests(users):
    print("  → Generating profiles & interests...")
    profiles, user_interests = [], []
    interest_idx = {name: i for i, name in enumerate(INTEREST_NAMES, start=1)}
    ui_set = set()

    for user in users:
        uid    = user["user_id"]
        gender = random.choice(GENDERS)
        first  = fake.first_name_male() if gender == "male" else fake.first_name_female()
        last   = fake.last_name()
        dob    = random_dob(18, 50)
        age    = age_from_dob(dob)
        city, country, lat, lon = random.choice(CITIES)
        lat = round(lat + random.uniform(-0.05, 0.05), 6)
        lon = round(lon + random.uniform(-0.05, 0.05), 6)
        min_age, max_age = sensible_age_prefs(age)
        occupation = random.choice(OCCUPATIONS)
        chosen     = random.sample(INTEREST_NAMES, random.randint(MIN_INTERESTS, MAX_INTERESTS))
        bio        = make_bio(first, occupation, chosen)

        profiles.append({
            "profile_id":       uid,
            "user_id":          uid,
            "first_name":       first,
            "last_name":        last,
            "date_of_birth":    dob,
            "gender":           gender,
            "bio":              bio,
            "profile_photo_url": None,
            "city":             city,
            "country":          country,
            "latitude":         lat,
            "longitude":        lon,
            "looking_for":      random.choice(LOOKING_FOR),
            "min_age_pref":     min_age,
            "max_age_pref":     max_age,
            "max_distance_km":  random.choice([10, 20, 30, 50, 100]),
            "occupation":       occupation,
            "education_level":  random.choice(EDUCATION_LEVELS),
            "relationship_goal": random.choice(REL_GOALS),
            "is_visible":       random.choice([True, True, True, False]),
        })

        for name in chosen:
            pair = (uid, interest_idx[name])
            if pair not in ui_set:
                ui_set.add(pair)
                user_interests.append({"user_id": uid, "interest_id": interest_idx[name]})

    print(f"     ✓ {len(profiles)} profiles, {len(user_interests)} user-interest links")
    return profiles, user_interests


def build_swipes(user_ids):
    print("  → Generating swipes...")
    swipes, like_set, seen = [], set(), set()
    swipe_id = 1
    # FIX: actions are plain strings — they insert into VARCHAR(10), not an ENUM type
    actions = ["like", "like", "like", "dislike", "pass"]
    for uid in user_ids:
        for other in user_ids:
            if uid == other or (uid, other) in seen:
                continue
            if random.random() > SWIPE_DENSITY:
                continue
            seen.add((uid, other))
            action = random.choice(actions)
            swipes.append({
                "swipe_id":  swipe_id,
                "swiper_id": uid,
                "swiped_id": other,
                "action":    action,
            })
            swipe_id += 1
            if action == "like":
                like_set.add((uid, other))
    print(f"     ✓ {len(swipes)} swipes")
    return swipes, like_set


def build_matches(like_set):
    print("  → Generating matches...")
    seen, matches, match_id = set(), [], 1
    for (a, b) in like_set:
        if (b, a) in like_set:
            pair = (min(a, b), max(a, b))
            if pair not in seen:
                seen.add(pair)
                matches.append({"match_id": match_id, "user1_id": pair[0], "user2_id": pair[1]})
                match_id += 1
    print(f"     ✓ {len(matches)} mutual matches")
    return matches


def build_conversations(matches):
    convs = [{"conversation_id": m["match_id"], "match_id": m["match_id"]} for m in matches]
    print(f"     ✓ {len(convs)} conversations")
    return convs


def build_messages(matches, conversations):
    print("  → Generating messages...")
    match_lookup = {m["match_id"]: (m["user1_id"], m["user2_id"]) for m in matches}
    conv_lookup  = {c["conversation_id"]: c["match_id"] for c in conversations}
    messages, message_id = [], 1

    for cid, mid in conv_lookup.items():
        u1, u2  = match_lookup[mid]
        senders = [u1, u2]
        random.shuffle(senders)
        num_msgs = random.randint(3, 10)
        for i in range(num_msgs):
            sender   = senders[i % 2]
            template = random.choice(MESSAGE_TEMPLATES)
            body     = template.replace("{interest}", random.choice(INTEREST_NAMES).lower())
            messages.append({
                "message_id":      message_id,
                "conversation_id": cid,
                "sender_id":       sender,
                "body":            body,
                "is_read":         i < (num_msgs - 1),
            })
            message_id += 1

    print(f"     ✓ {len(messages)} messages")
    return messages


def build_favorites(user_ids):
    rows, attempts = set(), 0
    while len(rows) < NUM_FAVORITES and attempts < NUM_FAVORITES * 10:
        attempts += 1
        u1, u2 = random.sample(user_ids, 2)
        rows.add((u1, u2))
    favs = [{"user_id": u1, "favorited_id": u2} for u1, u2 in rows]
    print(f"     ✓ {len(favs)} favorites")
    return favs


def build_profile_photos(user_ids):
    photos, photo_id = [], 1
    for uid in user_ids:
        for i in range(random.randint(1, 3)):
            photos.append({
                "photo_id":  photo_id,
                "user_id":   uid,
                "photo_url": f"https://picsum.photos/seed/{uid}-{i}/400/400",
                "is_primary": i == 0,
            })
            photo_id += 1
    print(f"     ✓ {len(photos)} profile photos")
    return photos


# ── SQL writers ────────────────────────────────────────────────────────────────

def section(lines, title):
    lines += [
        "-- ============================================================",
        f"-- {title}",
        "-- ============================================================",
    ]


def write_schema(lines):
    """
    Emit the complete DROP + CREATE schema so the output SQL file is
    fully self-contained. Key change: swipes.action is VARCHAR(10) with
    a CHECK constraint instead of a PostgreSQL ENUM type, so SQLAlchemy's
    String(10) column maps to it without any type conflicts.
    """
    section(lines, "SCHEMA — drop existing tables then recreate cleanly")
    lines += [
        "DROP TABLE IF EXISTS profile_photos   CASCADE;",
        "DROP TABLE IF EXISTS favorites        CASCADE;",
        "DROP TABLE IF EXISTS messages         CASCADE;",
        "DROP TABLE IF EXISTS conversations    CASCADE;",
        "DROP TABLE IF EXISTS matches          CASCADE;",
        "DROP TABLE IF EXISTS swipes           CASCADE;",
        "DROP TABLE IF EXISTS user_interests   CASCADE;",
        "DROP TABLE IF EXISTS interests        CASCADE;",
        "DROP TABLE IF EXISTS profiles         CASCADE;",
        "DROP TABLE IF EXISTS users            CASCADE;",
        "DROP TYPE  IF EXISTS swipe_action;",   # remove old ENUM if it exists
        "",
        "-- 1. USERS",
        "CREATE TABLE users (",
        "    user_id       SERIAL PRIMARY KEY,",
        "    username      VARCHAR(50)  NOT NULL UNIQUE,",
        "    email         VARCHAR(255) NOT NULL UNIQUE,",
        "    password_hash VARCHAR(255) NOT NULL,",
        "    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,",
        "    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),",
        "    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()",
        ");",
        "CREATE INDEX idx_users_email    ON users (email);",
        "CREATE INDEX idx_users_username ON users (username);",
        "",
        "-- 2. INTERESTS  (before profiles & user_interests)",
        "CREATE TABLE interests (",
        "    interest_id SERIAL PRIMARY KEY,",
        "    name        VARCHAR(100) NOT NULL UNIQUE,",
        "    category    VARCHAR(50)",
        ");",
        "CREATE INDEX idx_interests_category ON interests (category);",
        "",
        "-- 3. PROFILES",
        "CREATE TABLE profiles (",
        "    profile_id        SERIAL PRIMARY KEY,",
        "    user_id           INTEGER      NOT NULL UNIQUE REFERENCES users (user_id) ON DELETE CASCADE,",
        "    first_name        VARCHAR(50)  NOT NULL,",
        "    last_name         VARCHAR(50)  NOT NULL,",
        "    date_of_birth     DATE         NOT NULL,",
        "    gender            VARCHAR(20)  NOT NULL,",
        "    bio               TEXT,",
        "    profile_photo_url VARCHAR(500),",
        "    city              VARCHAR(100),",
        "    country           VARCHAR(100),",
        "    latitude          NUMERIC(9, 6),",
        "    longitude         NUMERIC(9, 6),",
        "    looking_for       VARCHAR(20)  NOT NULL DEFAULT 'any',",
        "    min_age_pref      SMALLINT     NOT NULL DEFAULT 18 CHECK (min_age_pref >= 18),",
        "    max_age_pref      SMALLINT     NOT NULL DEFAULT 99 CHECK (max_age_pref <= 99),",
        "    max_distance_km   SMALLINT     NOT NULL DEFAULT 50,",
        "    occupation        VARCHAR(100),",
        "    education_level   VARCHAR(50),",
        "    relationship_goal VARCHAR(50),",
        "    is_visible        BOOLEAN      NOT NULL DEFAULT TRUE,",
        "    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),",
        "    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()",
        ");",
        "CREATE INDEX idx_profiles_user_id  ON profiles (user_id);",
        "CREATE INDEX idx_profiles_location ON profiles (city, country);",
        "CREATE INDEX idx_profiles_coords   ON profiles (latitude, longitude);",
        "CREATE INDEX idx_profiles_visible  ON profiles (is_visible);",
        "",
        "-- 4. USER_INTERESTS",
        "CREATE TABLE user_interests (",
        "    user_id     INTEGER NOT NULL REFERENCES users     (user_id)      ON DELETE CASCADE,",
        "    interest_id INTEGER NOT NULL REFERENCES interests (interest_id)  ON DELETE CASCADE,",
        "    PRIMARY KEY (user_id, interest_id)",
        ");",
        "CREATE INDEX idx_user_interests_user     ON user_interests (user_id);",
        "CREATE INDEX idx_user_interests_interest ON user_interests (interest_id);",
        "",
        "-- 5. SWIPES — VARCHAR(10) instead of ENUM so SQLAlchemy String(10) maps cleanly",
        "CREATE TABLE swipes (",
        "    swipe_id   SERIAL PRIMARY KEY,",
        "    swiper_id  INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,",
        "    swiped_id  INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,",
        "    action     VARCHAR(10) NOT NULL CHECK (action IN ('like', 'dislike', 'pass')),",
        "    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),",
        "    CONSTRAINT swipes_no_self_swipe CHECK (swiper_id <> swiped_id),",
        "    CONSTRAINT swipes_unique_pair   UNIQUE (swiper_id, swiped_id)",
        ");",
        "CREATE INDEX idx_swipes_swiper ON swipes (swiper_id);",
        "CREATE INDEX idx_swipes_swiped ON swipes (swiped_id);",
        "CREATE INDEX idx_swipes_action ON swipes (action);",
        "",
        "-- 6. MATCHES",
        "CREATE TABLE matches (",
        "    match_id   SERIAL PRIMARY KEY,",
        "    user1_id   INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,",
        "    user2_id   INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,",
        "    matched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),",
        "    CONSTRAINT matches_no_self_match CHECK (user1_id <> user2_id)",
        ");",
        "CREATE UNIQUE INDEX idx_matches_unique_pair",
        "    ON matches (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id));",
        "CREATE INDEX idx_matches_user1 ON matches (user1_id);",
        "CREATE INDEX idx_matches_user2 ON matches (user2_id);",
        "",
        "-- 7. CONVERSATIONS",
        "CREATE TABLE conversations (",
        "    conversation_id SERIAL PRIMARY KEY,",
        "    match_id        INTEGER NOT NULL UNIQUE REFERENCES matches (match_id) ON DELETE CASCADE,",
        "    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()",
        ");",
        "CREATE INDEX idx_conversations_match ON conversations (match_id);",
        "",
        "-- 8. MESSAGES",
        "CREATE TABLE messages (",
        "    message_id      SERIAL PRIMARY KEY,",
        "    conversation_id INTEGER NOT NULL REFERENCES conversations (conversation_id) ON DELETE CASCADE,",
        "    sender_id       INTEGER NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,",
        "    body            TEXT    NOT NULL CHECK (LENGTH(TRIM(body)) > 0),",
        "    is_read         BOOLEAN NOT NULL DEFAULT FALSE,",
        "    sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()",
        ");",
        "CREATE INDEX idx_messages_conversation ON messages (conversation_id, sent_at);",
        "CREATE INDEX idx_messages_sender       ON messages (sender_id);",
        "CREATE INDEX idx_messages_unread       ON messages (conversation_id) WHERE NOT is_read;",
        "",
        "-- 9. FAVORITES",
        "CREATE TABLE favorites (",
        "    user_id      INTEGER NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,",
        "    favorited_id INTEGER NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,",
        "    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),",
        "    PRIMARY KEY (user_id, favorited_id),",
        "    CONSTRAINT favorites_no_self CHECK (user_id <> favorited_id)",
        ");",
        "CREATE INDEX idx_favorites_user ON favorites (user_id);",
        "",
        "-- 10. PROFILE_PHOTOS",
        "CREATE TABLE profile_photos (",
        "    photo_id    SERIAL PRIMARY KEY,",
        "    user_id     INTEGER      NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,",
        "    photo_url   VARCHAR(500) NOT NULL,",
        "    is_primary  BOOLEAN      NOT NULL DEFAULT FALSE,",
        "    uploaded_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()",
        ");",
        "CREATE INDEX idx_profile_photos_user ON profile_photos (user_id);",
        "",
        "-- Triggers for updated_at",
        "CREATE OR REPLACE FUNCTION set_updated_at()",
        "RETURNS TRIGGER AS $$",
        "BEGIN",
        "    NEW.updated_at = NOW();",
        "    RETURN NEW;",
        "END;",
        "$$ LANGUAGE plpgsql;",
        "",
        "CREATE TRIGGER trg_users_updated_at",
        "    BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();",
        "CREATE TRIGGER trg_profiles_updated_at",
        "    BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();",
        "",
    ]


def write_users(lines, users):
    section(lines, "USERS")
    for u in users:
        # FIX: include created_at and updated_at in column list and values.
        # These columns are NOT NULL so omitting them causes an error when the
        # table is created without a server-side default expression visible to
        # the psql client (SQLAlchemy sets defaults in Python, not the DB).
        lines.append(
            f"INSERT INTO users "
            f"(user_id, username, email, password_hash, is_active, created_at, updated_at) VALUES "
            f"({esc(u['user_id'])}, {esc(u['username'])}, {esc(u['email'])}, "
            f"{esc(u['password_hash'])}, {esc(u['is_active'])}, NOW(), NOW());"
        )
    lines.append(f"SELECT setval(pg_get_serial_sequence('users', 'user_id'), {len(users)}, true);")
    lines.append("")


def write_interests(lines):
    section(lines, "INTERESTS")
    for i, name in enumerate(INTEREST_NAMES, start=1):
        lines.append(
            f"INSERT INTO interests (interest_id, name, category) VALUES "
            f"({i}, {esc(name)}, {esc(INTEREST_CATEGORIES[name])}) ON CONFLICT (name) DO NOTHING;"
        )
    lines.append(
        f"SELECT setval(pg_get_serial_sequence('interests', 'interest_id'), {len(INTEREST_NAMES)}, true);"
    )
    lines.append("")


def write_profiles(lines, profiles):
    section(lines, "PROFILES")
    for p in profiles:
        lines.append(
            f"INSERT INTO profiles ("
            f"profile_id, user_id, first_name, last_name, date_of_birth, gender, bio, "
            f"profile_photo_url, city, country, latitude, longitude, "
            f"looking_for, min_age_pref, max_age_pref, max_distance_km, "
            f"occupation, education_level, relationship_goal, is_visible) VALUES ("
            f"{esc(p['profile_id'])}, {esc(p['user_id'])}, {esc(p['first_name'])}, "
            f"{esc(p['last_name'])}, {esc(p['date_of_birth'])}, {esc(p['gender'])}, "
            f"{esc(p['bio'])}, {esc(p['profile_photo_url'])}, {esc(p['city'])}, "
            f"{esc(p['country'])}, {esc(p['latitude'])}, {esc(p['longitude'])}, "
            f"{esc(p['looking_for'])}, {esc(p['min_age_pref'])}, {esc(p['max_age_pref'])}, "
            f"{esc(p['max_distance_km'])}, {esc(p['occupation'])}, "
            f"{esc(p['education_level'])}, {esc(p['relationship_goal'])}, {esc(p['is_visible'])});"
        )
    lines.append(
        f"SELECT setval(pg_get_serial_sequence('profiles', 'profile_id'), {len(profiles)}, true);"
    )
    lines.append("")


def write_user_interests(lines, user_interests):
    section(lines, "USER_INTERESTS")
    for ui in user_interests:
        lines.append(
            f"INSERT INTO user_interests (user_id, interest_id) VALUES "
            f"({esc(ui['user_id'])}, {esc(ui['interest_id'])}) ON CONFLICT DO NOTHING;"
        )
    lines.append("")


def write_swipes(lines, swipes):
    section(lines, "SWIPES")
    for s in swipes:
        # action is a plain string ('like'|'dislike'|'pass') — inserts into
        # VARCHAR(10) column; no ENUM cast needed
        lines.append(
            f"INSERT INTO swipes (swipe_id, swiper_id, swiped_id, action) VALUES "
            f"({esc(s['swipe_id'])}, {esc(s['swiper_id'])}, {esc(s['swiped_id'])}, "
            f"{esc(s['action'])}) ON CONFLICT DO NOTHING;"
        )
    lines.append(
        f"SELECT setval(pg_get_serial_sequence('swipes', 'swipe_id'), {len(swipes)}, true);"
    )
    lines.append("")


def write_matches(lines, matches):
    section(lines, "MATCHES")
    for m in matches:
        lines.append(
            f"INSERT INTO matches (match_id, user1_id, user2_id) VALUES "
            f"({esc(m['match_id'])}, {esc(m['user1_id'])}, {esc(m['user2_id'])}) ON CONFLICT DO NOTHING;"
        )
    lines.append(
        f"SELECT setval(pg_get_serial_sequence('matches', 'match_id'), {len(matches)}, true);"
    )
    lines.append("")


def write_conversations(lines, conversations):
    section(lines, "CONVERSATIONS")
    for c in conversations:
        lines.append(
            f"INSERT INTO conversations (conversation_id, match_id) VALUES "
            f"({esc(c['conversation_id'])}, {esc(c['match_id'])}) ON CONFLICT DO NOTHING;"
        )
    lines.append(
        f"SELECT setval(pg_get_serial_sequence('conversations', 'conversation_id'), {len(conversations)}, true);"
    )
    lines.append("")


def write_messages(lines, messages):
    section(lines, "MESSAGES")
    for m in messages:
        lines.append(
            f"INSERT INTO messages (message_id, conversation_id, sender_id, body, is_read) VALUES "
            f"({esc(m['message_id'])}, {esc(m['conversation_id'])}, {esc(m['sender_id'])}, "
            f"{esc(m['body'])}, {esc(m['is_read'])});"
        )
    lines.append(
        f"SELECT setval(pg_get_serial_sequence('messages', 'message_id'), {len(messages)}, true);"
    )
    lines.append("")


def write_favorites(lines, favorites):
    section(lines, "FAVORITES")
    for f in favorites:
        lines.append(
            f"INSERT INTO favorites (user_id, favorited_id) VALUES "
            f"({esc(f['user_id'])}, {esc(f['favorited_id'])}) ON CONFLICT DO NOTHING;"
        )
    lines.append("")


def write_profile_photos(lines, photos):
    section(lines, "PROFILE_PHOTOS")
    for p in photos:
        lines.append(
            f"INSERT INTO profile_photos (photo_id, user_id, photo_url, is_primary) VALUES "
            f"({esc(p['photo_id'])}, {esc(p['user_id'])}, {esc(p['photo_url'])}, {esc(p['is_primary'])});"
        )
    lines.append(
        f"SELECT setval(pg_get_serial_sequence('profile_photos', 'photo_id'), {len(photos)}, true);"
    )
    lines.append("")


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    print("\n🌱  DriftDater SQL seed generator starting...\n")

    users                    = build_users()
    profiles, user_interests = build_profiles_and_interests(users)
    user_ids                 = [u["user_id"] for u in users]
    swipes, like_set         = build_swipes(user_ids)
    matches                  = build_matches(like_set)
    conversations            = build_conversations(matches)
    messages                 = build_messages(matches, conversations)
    favorites                = build_favorites(user_ids)
    profile_photos           = build_profile_photos(user_ids)

    lines = [
        "-- ============================================================",
        "-- DriftDater — Complete Schema + Seed Data",
        f"-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"-- Users: {len(users)} | Matches: {len(matches)} | Messages: {len(messages)}",
        "-- Test password for all accounts: Password123!",
        "-- ============================================================",
        "",
        "BEGIN;",
        "",
    ]

    # Write full schema first (drops old tables, creates fresh ones)
    write_schema(lines)

    # Write all seed data
    write_users(lines, users)
    write_interests(lines)
    write_profiles(lines, profiles)
    write_user_interests(lines, user_interests)
    write_swipes(lines, swipes)
    write_matches(lines, matches)
    write_conversations(lines, conversations)
    write_messages(lines, messages)
    write_favorites(lines, favorites)
    write_profile_photos(lines, profile_photos)

    lines += ["COMMIT;", "", "-- Seed complete!"]

    Path(OUTPUT_FILE).write_text("\n".join(lines), encoding="utf-8")

    print(f"\n✅  Done! SQL written to: {OUTPUT_FILE}")
    print(f"    Import with:  psql -U postgres -d driftdater -f {OUTPUT_FILE}")
    print(f"    Test password for all users: Password123!\n")


if __name__ == "__main__":
    main()
