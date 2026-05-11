from faker import Faker
import random
from datetime import datetime, timedelta
from collections import defaultdict
from werkzeug.security import generate_password_hash  # ← FIX: real password hashing

fake = Faker()
random.seed(42)
Faker.seed(42)

# ============================================================
# CONFIGURATION
# ============================================================
NUM_USERS = 150
MAX_PHOTOS_PER_USER = 5
MAX_MESSAGES_PER_MATCH = 25
OUTPUT_FILE = "driftdater_seed_data.sql"

# ============================================================
# PASSWORD
# Pre-compute ONE real Werkzeug hash for "password123".
# Every seeded user gets this same hash, so you can log in
# to ANY account using:  password123
# ============================================================
SEED_PASSWORD       = 'password123'
SEED_PASSWORD_HASH  = generate_password_hash(SEED_PASSWORD)

# ============================================================
# STATIC DATA
# ============================================================
GENDERS = ['male', 'female', 'non_binary', 'other']
LOOKING_FOR = ['male', 'female', 'non_binary', 'any']
RELATIONSHIP_GOALS = ['casual', 'serious', 'friendship', 'marriage']
EDUCATION_LEVELS = [
    'high_school',
    'associate',
    'bachelors',
    'masters',
    'phd',
    'other'
]

INTERESTS = [
    'Hiking',
    'Photography',
    'Gaming',
    'Cooking',
    'Traveling',
    'Music',
    'Reading',
    'Fitness',
    'Dancing',
    'Movies',
    'Coffee',
    'Yoga',
    'Painting',
    'Cycling',
    'Swimming',
    'Volunteering',
    'Technology',
    'Fashion',
    'Gardening',
    'Board Games'
]

JAMAICAN_CITIES = [
    ('Kingston', 'Jamaica', 17.9712, -76.7936),
    ('Montego Bay', 'Jamaica', 18.4762, -77.8939),
    ('Spanish Town', 'Jamaica', 17.9911, -76.9570),
    ('Portmore', 'Jamaica', 17.9500, -76.8820),
    ('Mandeville', 'Jamaica', 18.0417, -77.5071),
    ('Ocho Rios', 'Jamaica', 18.4079, -77.1031),
    ('Negril', 'Jamaica', 18.2683, -78.3482),
    ('May Pen', 'Jamaica', 17.9659, -77.2451)
]

PROFILE_BIOS = [
    'Adventure seeker who loves meaningful conversations and spontaneous road trips.',
    'Big foodie, gym enthusiast, and coffee addict.',
    'Looking for someone genuine to explore life with.',
    'Tech lover who enjoys movies, gaming, and traveling.',
    'Creative soul with a passion for photography and music.',
    'Fitness-focused but also loves lazy Sundays and Netflix.',
    'Always planning the next trip or trying a new restaurant.',
    'Easygoing personality who values honesty and humor.',
    'Nature lover who enjoys hiking and beach sunsets.',
    'Bookworm with a sarcastic sense of humor.'
]

# ============================================================
# HELPERS
# ============================================================
def sql_escape(value):
    if value is None:
        return 'NULL'

    if isinstance(value, bool):
        return 'TRUE' if value else 'FALSE'

    if isinstance(value, (int, float)):
        return str(value)

    return "'{}'".format(str(value).replace("'", "''"))


def random_birthdate(min_age=18, max_age=55):
    today = datetime.now().date()
    age = random.randint(min_age, max_age)
    days = random.randint(0, 364)
    return today - timedelta(days=(age * 365 + days))


def random_recent_datetime(days_back=365):
    return fake.date_time_between(start_date=f'-{days_back}d', end_date='now')


def generate_username(first_name, last_name, existing):
    while True:
        username = (
            f"{first_name.lower()}{last_name.lower()}"
            f"{random.randint(10, 9999)}"
        )

        if username not in existing:
            existing.add(username)
            return username


# ============================================================
# STORAGE
# ============================================================
users = []
profiles = []
user_interests = []
profile_photos = []
swipes = []
matches = []
conversations = []
messages = []
favorites = []
notifications = []
user_blocks = []
user_reports = []

used_usernames = set()
used_emails = set()
match_lookup = {}

# ============================================================
# GENERATE USERS + PROFILES
# ============================================================
for user_id in range(1, NUM_USERS + 1):
    first_name = fake.first_name()
    last_name = fake.last_name()

    username = generate_username(first_name, last_name, used_usernames)

    email = f"{username}@example.com"
    while email in used_emails:
        email = f"{username}{random.randint(1,999)}@example.com"

    used_emails.add(email)

    created_at = random_recent_datetime(700)

    users.append({
        'user_id': user_id,
        'username': username,
        'email': email,
        'password_hash': SEED_PASSWORD_HASH,   # ← FIX: was fake.sha256()
        'email_verified': random.random() < 0.92,
        'verification_token': None,
        'password_reset_token': None,
        'password_reset_expires': None,
        'is_active': random.random() < 0.98,
        'last_seen_at': random_recent_datetime(7),
        'created_at': created_at,
        'updated_at': created_at
    })

    city, country, lat, lon = random.choice(JAMAICAN_CITIES)

    profiles.append({
        'user_id': user_id,
        'first_name': first_name,
        'last_name': last_name,
        'date_of_birth': random_birthdate(),
        'gender': random.choice(GENDERS),
        'bio': random.choice(PROFILE_BIOS),
        'city': city,
        'country': country,
        'latitude': round(lat + random.uniform(-0.05, 0.05), 6),
        'longitude': round(lon + random.uniform(-0.05, 0.05), 6),
        'looking_for': random.choice(LOOKING_FOR),
        'min_age_pref': random.randint(18, 25),
        'max_age_pref': random.randint(26, 55),
        'max_distance_km': random.choice([10, 25, 50, 75, 100]),
        'occupation': fake.job(),
        'education_level': random.choice(EDUCATION_LEVELS),
        'relationship_goal': random.choice(RELATIONSHIP_GOALS),
        'is_visible': random.random() < 0.95,
        'created_at': created_at,
        'updated_at': created_at
    })

# ============================================================
# USER INTERESTS
# ============================================================
for user_id in range(1, NUM_USERS + 1):
    selected = random.sample(range(1, len(INTERESTS) + 1), random.randint(3, 7))

    for interest_id in selected:
        user_interests.append((user_id, interest_id))

# ============================================================
# PROFILE PHOTOS
# ============================================================
photo_id = 1

for user_id in range(1, NUM_USERS + 1):
    num_photos = random.randint(1, MAX_PHOTOS_PER_USER)

    primary_photo = random.randint(1, num_photos)

    for i in range(1, num_photos + 1):
        profile_photos.append({
            'photo_id': photo_id,
            'user_id': user_id,
            'photo_url': f'https://picsum.photos/seed/user{user_id}_{i}/500/500',
            'is_primary': i == primary_photo,
            'uploaded_at': random_recent_datetime(365),
            'updated_at': random_recent_datetime(365)
        })

        photo_id += 1

# ============================================================
# SWIPES + MATCHES
# ============================================================
swipe_id = 1
match_id = 1
conversation_id = 1

existing_swipes = set()

for user_id in range(1, NUM_USERS + 1):
    targets = random.sample(
        [u for u in range(1, NUM_USERS + 1) if u != user_id],
        random.randint(15, 40)
    )

    for target_id in targets:
        if (user_id, target_id) in existing_swipes:
            continue

        existing_swipes.add((user_id, target_id))

        action = random.choices(
            ['like', 'dislike', 'pass'],
            weights=[0.45, 0.35, 0.20],
            k=1
        )[0]

        created_at = random_recent_datetime(180)

        swipes.append({
            'swipe_id': swipe_id,
            'swiper_id': user_id,
            'swiped_id': target_id,
            'action': action,
            'created_at': created_at,
            'updated_at': created_at
        })

        swipe_id += 1

# Detect mutual likes
like_pairs = defaultdict(set)

for swipe in swipes:
    if swipe['action'] == 'like':
        like_pairs[swipe['swiper_id']].add(swipe['swiped_id'])

for user_a in like_pairs:
    for user_b in like_pairs[user_a]:
        if user_a in like_pairs[user_b]:
            ordered = tuple(sorted([user_a, user_b]))

            if ordered not in match_lookup:
                match_lookup[ordered] = match_id

                matched_at = random_recent_datetime(120)

                matches.append({
                    'match_id': match_id,
                    'user1_id': ordered[0],
                    'user2_id': ordered[1],
                    'status': 'active',
                    'matched_at': matched_at
                })

                conversations.append({
                    'conversation_id': conversation_id,
                    'match_id': match_id,
                    'created_at': matched_at
                })

                conversation_id += 1
                match_id += 1

# ============================================================
# MESSAGES
# ============================================================
message_id = 1

for convo in conversations:
    match = next(m for m in matches if m['match_id'] == convo['match_id'])

    users_in_match = [match['user1_id'], match['user2_id']]

    num_messages = random.randint(3, MAX_MESSAGES_PER_MATCH)

    for _ in range(num_messages):
        sender = random.choice(users_in_match)

        messages.append({
            'message_id': message_id,
            'conversation_id': convo['conversation_id'],
            'sender_id': sender,
            'body': fake.sentence(nb_words=random.randint(5, 18)),
            'is_read': random.random() < 0.8,
            'sent_at': random_recent_datetime(90)
        })

        message_id += 1

# ============================================================
# FAVORITES
# ============================================================
favorite_pairs = set()

for user_id in range(1, NUM_USERS + 1):
    targets = random.sample(
        [u for u in range(1, NUM_USERS + 1) if u != user_id],
        random.randint(2, 10)
    )

    for target in targets:
        if (user_id, target) not in favorite_pairs:
            favorite_pairs.add((user_id, target))

            favorites.append({
                'user_id': user_id,
                'favorited_id': target,
                'created_at': random_recent_datetime(120),
                'updated_at': random_recent_datetime(120)
            })

# ============================================================
# NOTIFICATIONS
# ============================================================
notification_id = 1

notification_types = [
    'match',
    'message',
    'favorite',
    'like'
]

for user_id in range(1, NUM_USERS + 1):
    for _ in range(random.randint(3, 12)):
        ntype = random.choice(notification_types)

        notifications.append({
            'notification_id': notification_id,
            'user_id': user_id,
            'type': ntype,
            'message': fake.sentence(nb_words=10),
            'is_read': random.random() < 0.7,
            'created_at': random_recent_datetime(60)
        })

        notification_id += 1

# ============================================================
# BLOCKS + REPORTS
# ============================================================
block_pairs = set()

for _ in range(20):
    blocker = random.randint(1, NUM_USERS)
    blocked = random.randint(1, NUM_USERS)

    if blocker != blocked and (blocker, blocked) not in block_pairs:
        block_pairs.add((blocker, blocked))

        user_blocks.append({
            'blocker_id': blocker,
            'blocked_id': blocked,
            'created_at': random_recent_datetime(90)
        })

for _ in range(25):
    reporter = random.randint(1, NUM_USERS)
    reported = random.randint(1, NUM_USERS)

    if reporter != reported:
        user_reports.append({
            'reporter_id': reporter,
            'reported_id': reported,
            'reason': random.choice([
                'Spam account',
                'Harassment',
                'Fake profile',
                'Inappropriate messages',
                'Offensive content'
            ]),
            'created_at': random_recent_datetime(90)
        })

# ============================================================
# SQL GENERATION
# ============================================================
with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:

    f.write('-- ============================================================\n')
    f.write('-- DriftDater Fake Seed Data\n')
    f.write('-- Generated Using Faker\n')
    f.write(f'-- Password for ALL users: {SEED_PASSWORD}\n')
    f.write('-- ============================================================\n\n')

    # USERS
    f.write('-- USERS\n')

    for u in users:
        f.write(
            f"INSERT INTO users "
            f"(user_id, username, email, password_hash, email_verified, "
            f"verification_token, password_reset_token, password_reset_expires, "
            f"is_active, last_seen_at, created_at, updated_at) VALUES ("
            f"{sql_escape(u['user_id'])}, "
            f"{sql_escape(u['username'])}, "
            f"{sql_escape(u['email'])}, "
            f"{sql_escape(u['password_hash'])}, "
            f"{sql_escape(u['email_verified'])}, "
            f"{sql_escape(u['verification_token'])}, "
            f"{sql_escape(u['password_reset_token'])}, "
            f"{sql_escape(u['password_reset_expires'])}, "
            f"{sql_escape(u['is_active'])}, "
            f"{sql_escape(u['last_seen_at'])}, "
            f"{sql_escape(u['created_at'])}, "
            f"{sql_escape(u['updated_at'])});\n"
        )

    # PROFILES
    f.write('\n-- PROFILES\n')

    for p in profiles:
        f.write(
            f"INSERT INTO profiles "
            f"(user_id, first_name, last_name, date_of_birth, gender, bio, city, country, latitude, longitude, looking_for, min_age_pref, max_age_pref, max_distance_km, occupation, education_level, relationship_goal, is_visible, created_at, updated_at) VALUES ("
            f"{sql_escape(p['user_id'])}, "
            f"{sql_escape(p['first_name'])}, "
            f"{sql_escape(p['last_name'])}, "
            f"{sql_escape(p['date_of_birth'])}, "
            f"{sql_escape(p['gender'])}, "
            f"{sql_escape(p['bio'])}, "
            f"{sql_escape(p['city'])}, "
            f"{sql_escape(p['country'])}, "
            f"{sql_escape(p['latitude'])}, "
            f"{sql_escape(p['longitude'])}, "
            f"{sql_escape(p['looking_for'])}, "
            f"{sql_escape(p['min_age_pref'])}, "
            f"{sql_escape(p['max_age_pref'])}, "
            f"{sql_escape(p['max_distance_km'])}, "
            f"{sql_escape(p['occupation'])}, "
            f"{sql_escape(p['education_level'])}, "
            f"{sql_escape(p['relationship_goal'])}, "
            f"{sql_escape(p['is_visible'])}, "
            f"{sql_escape(p['created_at'])}, "
            f"{sql_escape(p['updated_at'])});\n"
        )

    # USER INTERESTS
    f.write('\n-- USER INTERESTS\n')

    for user_id, interest_id in user_interests:
        f.write(
            f"INSERT INTO user_interests (user_id, interest_id) VALUES ("
            f"{user_id}, {interest_id});\n"
        )

    # PROFILE PHOTOS
    f.write('\n-- PROFILE PHOTOS\n')

    for photo in profile_photos:
        f.write(
            f"INSERT INTO profile_photos "
            f"(photo_id, user_id, photo_url, is_primary, uploaded_at, updated_at) VALUES ("
            f"{sql_escape(photo['photo_id'])}, "
            f"{sql_escape(photo['user_id'])}, "
            f"{sql_escape(photo['photo_url'])}, "
            f"{sql_escape(photo['is_primary'])}, "
            f"{sql_escape(photo['uploaded_at'])}, "
            f"{sql_escape(photo['updated_at'])});\n"
        )

    # SWIPES
    f.write('\n-- SWIPES\n')

    for swipe in swipes:
        f.write(
            f"INSERT INTO swipes "
            f"(swipe_id, swiper_id, swiped_id, action, created_at, updated_at) VALUES ("
            f"{sql_escape(swipe['swipe_id'])}, "
            f"{sql_escape(swipe['swiper_id'])}, "
            f"{sql_escape(swipe['swiped_id'])}, "
            f"{sql_escape(swipe['action'])}, "
            f"{sql_escape(swipe['created_at'])}, "
            f"{sql_escape(swipe['updated_at'])});\n"
        )

    # MATCHES
    f.write('\n-- MATCHES\n')

    for match in matches:
        f.write(
            f"INSERT INTO matches "
            f"(match_id, user1_id, user2_id, status, matched_at) VALUES ("
            f"{sql_escape(match['match_id'])}, "
            f"{sql_escape(match['user1_id'])}, "
            f"{sql_escape(match['user2_id'])}, "
            f"{sql_escape(match['status'])}, "
            f"{sql_escape(match['matched_at'])});\n"
        )

    # CONVERSATIONS
    f.write('\n-- CONVERSATIONS\n')

    for convo in conversations:
        f.write(
            f"INSERT INTO conversations "
            f"(conversation_id, match_id, created_at) VALUES ("
            f"{sql_escape(convo['conversation_id'])}, "
            f"{sql_escape(convo['match_id'])}, "
            f"{sql_escape(convo['created_at'])});\n"
        )

    # MESSAGES
    f.write('\n-- MESSAGES\n')

    for msg in messages:
        f.write(
            f"INSERT INTO messages "
            f"(message_id, conversation_id, sender_id, body, is_read, sent_at) VALUES ("
            f"{sql_escape(msg['message_id'])}, "
            f"{sql_escape(msg['conversation_id'])}, "
            f"{sql_escape(msg['sender_id'])}, "
            f"{sql_escape(msg['body'])}, "
            f"{sql_escape(msg['is_read'])}, "
            f"{sql_escape(msg['sent_at'])});\n"
        )

    # FAVORITES
    f.write('\n-- FAVORITES\n')

    for fav in favorites:
        f.write(
            f"INSERT INTO favorites "
            f"(user_id, favorited_id, created_at, updated_at) VALUES ("
            f"{sql_escape(fav['user_id'])}, "
            f"{sql_escape(fav['favorited_id'])}, "
            f"{sql_escape(fav['created_at'])}, "
            f"{sql_escape(fav['updated_at'])});\n"
        )

    # NOTIFICATIONS
    f.write('\n-- NOTIFICATIONS\n')

    for n in notifications:
        f.write(
            f"INSERT INTO notifications "
            f"(notification_id, user_id, type, message, is_read, created_at) VALUES ("
            f"{sql_escape(n['notification_id'])}, "
            f"{sql_escape(n['user_id'])}, "
            f"{sql_escape(n['type'])}, "
            f"{sql_escape(n['message'])}, "
            f"{sql_escape(n['is_read'])}, "
            f"{sql_escape(n['created_at'])});\n"
        )

    # USER BLOCKS
    f.write('\n-- USER BLOCKS\n')

    for block in user_blocks:
        f.write(
            f"INSERT INTO user_blocks "
            f"(blocker_id, blocked_id, created_at) VALUES ("
            f"{sql_escape(block['blocker_id'])}, "
            f"{sql_escape(block['blocked_id'])}, "
            f"{sql_escape(block['created_at'])});\n"
        )

    # USER REPORTS
    f.write('\n-- USER REPORTS\n')

    for report in user_reports:
        f.write(
            f"INSERT INTO user_reports "
            f"(reporter_id, reported_id, reason, created_at) VALUES ("
            f"{sql_escape(report['reporter_id'])}, "
            f"{sql_escape(report['reported_id'])}, "
            f"{sql_escape(report['reason'])}, "
            f"{sql_escape(report['created_at'])});\n"
        )

# ============================================================
# PRINT SUMMARY + ALL LOGIN CREDENTIALS
# ============================================================
print('=' * 62)
print(f'  SQL file generated: {OUTPUT_FILE}')
print('=' * 62)
print(f'  Users:         {len(users)}')
print(f'  Profiles:      {len(profiles)}')
print(f'  User Interests:{len(user_interests)}')
print(f'  Photos:        {len(profile_photos)}')
print(f'  Swipes:        {len(swipes)}')
print(f'  Matches:       {len(matches)}')
print(f'  Conversations: {len(conversations)}')
print(f'  Messages:      {len(messages)}')
print(f'  Favorites:     {len(favorites)}')
print(f'  Notifications: {len(notifications)}')
print(f'  Blocks:        {len(user_blocks)}')
print(f'  Reports:       {len(user_reports)}')
print('=' * 62)
print()
print('=' * 62)
print(f'  LOGIN CREDENTIALS  —  password for ALL users: {SEED_PASSWORD}')
print('=' * 62)
print(f'  {"ID":<5} {"EMAIL":<38} FIRST NAME')
print('-' * 62)
for u, p in zip(users, profiles):
    print(f'  {u["user_id"]:<5} {u["email"]:<38} {p["first_name"]}')
print('=' * 62)
print(f'  Password for every account above: {SEED_PASSWORD}')
print('=' * 62)
