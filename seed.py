"""
DriftDater — Development Seed Script
Run: python seed.py

Creates 30 realistic fake users with profiles, interests, photos, swipes,
matches and messages so you can test the app immediately.
"""
import random
from datetime import datetime, timezone, date, timedelta
from app import create_app, db
from app.models import (
    User, Profile, Interest, ProfilePhoto, Swipe, SwipeAction,
    Match, MatchStatusType, Conversation, Message, Favorite,
    Notification, GenderType, LookingForType, RelationshipGoalType,
    EducationLevelType
)

FIRST_NAMES = [
    'Aaliya','Brandon','Camille','Devon','Erica','Fabian','Grace','Hassan',
    'Imani','Jordan','Keisha','Leroy','Monique','Noel','Olive','Patrick',
    'Queen','Raheem','Stephanie','Tariq','Ursula','Victor','Wendy','Xavier',
    'Yolanda','Zach','Alicia','Benji','Crystal','Darien'
]
LAST_NAMES = [
    'Brown','Campbell','Davis','Edwards','Francis','Gordon','Henry',
    'Jackson','King','Lewis','Mason','Nelson','Oliver','Palmer',
    'Reid','Smith','Taylor','Underwood','Walters','Young'
]
CITIES = [
    ('Kingston','Jamaica',17.97,-76.79),
    ('Montego Bay','Jamaica',18.47,-77.89),
    ('Spanish Town','Jamaica',17.99,-76.95),
    ('Portmore','Jamaica',17.95,-76.88),
    ('Mandeville','Jamaica',18.04,-77.51),
    ('Ocho Rios','Jamaica',18.40,-77.10),
    ('Negril','Jamaica',18.27,-78.35),
    ('May Pen','Jamaica',17.96,-77.24),
]
BIOS = [
    'Adventure seeker who loves good conversation and spontaneous road trips.',
    'Foodie, gym enthusiast, and proud coffee addict. Looking for my person.',
    'Creative soul with a passion for photography and live music.',
    'Fitness-focused but also loves lazy Sundays and Netflix marathons.',
    'Nature lover. Beach sunsets are my therapy.',
    'Tech nerd by day, amateur chef by night. Let\'s cook together.',
    'Easygoing, honest, and always up for a laugh. DM me!',
    'Bookworm with a sarcastic edge. Looking for someone equally weird.',
    'Always planning the next trip or trying a new restaurant in Kingston.',
    'Big on family values and meaningful connections.',
]
OCCUPATIONS = [
    'Software Engineer','Nurse','Teacher','Accountant','Marketing Manager',
    'Graphic Designer','Lawyer','Entrepreneur','Chef','Architect',
    'Data Analyst','Doctor','Journalist','HR Manager','Pharmacist',
]
MESSAGES_POOL = [
    'Hey! How are you doing?',
    'I saw you like hiking too — any favourite trails?',
    'Your bio made me smile 😊',
    'What\'s your favourite spot in Kingston?',
    'We should grab coffee sometime!',
    'I love that you\'re into photography. What do you shoot?',
    'Been to Negril lately? I\'m planning a trip.',
    'Haha, you\'re hilarious! Love your energy.',
    'What kind of music are you into?',
    'I could really use a hiking buddy 😄',
    'That\'s so cool, I\'ve always wanted to try that!',
    'We have so much in common, this is exciting!',
    'Tell me more about yourself.',
    'What are you doing this weekend?',
    'I think we\'d get along really well.',
]


def random_dob(min_age=21, max_age=45):
    today = date.today()
    age = random.randint(min_age, max_age)
    return today - timedelta(days=age*365 + random.randint(0,364))


def random_dt(days_back=180):
    return datetime.now(timezone.utc) - timedelta(
        days=random.randint(0, days_back),
        hours=random.randint(0, 23),
        minutes=random.randint(0, 59)
    )


def run():
    app = create_app()
    with app.app_context():
        if User.query.count() > 5:
            print('Database already has users — skipping seed.')
            return

        # Seed interests if not present
        INTERESTS = [
            ("Hiking", "Outdoors"), ("Beach", "Outdoors"), ("Camping", "Outdoors"),
            ("Photography", "Creative"), ("Painting", "Creative"), ("Music", "Creative"),
            ("Cooking", "Food"), ("Baking", "Food"), ("Wine Tasting", "Food"),
            ("Reading", "Lifestyle"), ("Travel", "Lifestyle"), ("Yoga", "Lifestyle"),
            ("Gym", "Fitness"), ("Running", "Fitness"), ("Swimming", "Fitness"),
            ("Movies", "Entertainment"), ("Gaming", "Entertainment"), ("Netflix", "Entertainment"),
            ("Dancing", "Social"), ("Coffee", "Social"), ("Foodie", "Social"),
        ]
        for name, category in INTERESTS:
            if not Interest.query.filter_by(name=name).first():
                db.session.add(Interest(name=name, category=category))
        db.session.commit()

        all_interests = Interest.query.all()
        
        print('Seeding 30 users…')
        users = []
        used_names = set()

        for i in range(30):
            first = random.choice(FIRST_NAMES)
            last  = random.choice(LAST_NAMES)
            while f'{first}{last}' in used_names:
                first = random.choice(FIRST_NAMES)
                last  = random.choice(LAST_NAMES)
            used_names.add(f'{first}{last}')

            username = f'{first.lower()}{last.lower()}{random.randint(10,999)}'
            email    = f'{username}@example.com'

            gender  = random.choice(list(GenderType))
            city, country, lat, lon = random.choice(CITIES)
            lat += random.uniform(-0.05, 0.05)
            lon += random.uniform(-0.05, 0.05)

            u = User(
                username=username, email=email,
                email_verified=True, is_active=True,
                last_seen_at=random_dt(7),
                created_at=random_dt(365)
            )
            u.set_password('password123')
            db.session.add(u)
            db.session.flush()

            p = Profile(
                user_id=u.user_id,
                first_name=first, last_name=last,
                date_of_birth=random_dob(),
                gender=gender,
                bio=random.choice(BIOS),
                city=city, country=country,
                latitude=round(lat,6), longitude=round(lon,6),
                looking_for=random.choice(list(LookingForType)),
                min_age_pref=random.randint(18,25),
                max_age_pref=random.randint(28,50),
                max_distance_km=random.choice([10,25,50,75,100]),
                occupation=random.choice(OCCUPATIONS),
                education_level=random.choice(list(EducationLevelType)),
                relationship_goal=random.choice(list(RelationshipGoalType)),
                is_visible=True,
            )
            db.session.add(p)

            # Assign 3–7 interests
            u.interests = random.sample(all_interests, random.randint(3,7))

            # Primary placeholder photo (uses UI Avatars so no actual upload needed)
            photo_url = f'https://ui-avatars.com/api/?name={first}+{last}&background=e91e8c&color=fff&size=400&bold=true'
            photo = ProfilePhoto(user_id=u.user_id, photo_url=photo_url, is_primary=True)
            db.session.add(photo)

            users.append(u)

        db.session.commit()
        print(f'Created {len(users)} users.')

        # Generate swipes with ~40% like rate
        print('Generating swipes & matches…')
        matches_created = 0
        swipe_pairs = set()

        for u in users:
            targets = random.sample([x for x in users if x.user_id != u.user_id],
                                    random.randint(10, 20))
            for target in targets:
                if (u.user_id, target.user_id) in swipe_pairs:
                    continue
                swipe_pairs.add((u.user_id, target.user_id))
                action = random.choices(
                    [SwipeAction.like, SwipeAction.dislike, SwipeAction.pass_],
                    weights=[40, 40, 20]
                )[0]
                sw = Swipe(swiper_id=u.user_id, swiped_id=target.user_id,
                           action=action, created_at=random_dt(90))
                db.session.add(sw)

        db.session.commit()

        # Detect mutual likes → create matches + conversations + messages
        likes = {}
        for sw in Swipe.query.filter_by(action=SwipeAction.like).all():
            likes.setdefault(sw.swiper_id, set()).add(sw.swiped_id)

        for uid_a, liked_set in likes.items():
            for uid_b in liked_set:
                if uid_b not in likes or uid_a not in likes[uid_b]:
                    continue
                u1, u2 = (uid_a, uid_b) if uid_a < uid_b else (uid_b, uid_a)
                if Match.query.filter_by(user1_id=u1, user2_id=u2).first():
                    continue

                m = Match(user1_id=u1, user2_id=u2,
                          status=MatchStatusType.active,
                          matched_at=random_dt(60))
                db.session.add(m)
                db.session.flush()

                c = Conversation(match_id=m.match_id, created_at=m.matched_at)
                db.session.add(c)
                db.session.flush()

                # Add 3–12 messages
                speakers = [u1, u2]
                for _ in range(random.randint(3, 12)):
                    msg = Message(
                        conversation_id=c.conversation_id,
                        sender_id=random.choice(speakers),
                        body=random.choice(MESSAGES_POOL),
                        is_read=random.random() < 0.8,
                        sent_at=random_dt(30)
                    )
                    db.session.add(msg)

                matches_created += 1

        db.session.commit()
        print(f'Created {matches_created} matches with conversations.')

        # Favorites
        print('Creating favorites…')
        fav_pairs = set()
        for u in users:
            targets = random.sample([x for x in users if x.user_id != u.user_id],
                                    random.randint(2, 6))
            for t in targets:
                if (u.user_id, t.user_id) not in fav_pairs:
                    fav_pairs.add((u.user_id, t.user_id))
                    fav = Favorite(user_id=u.user_id, favorited_id=t.user_id,
                                   created_at=random_dt(60))
                    db.session.add(fav)
        db.session.commit()
        print(f'Created {len(fav_pairs)} favorites.')

        # Notifications
        print('Creating notifications…')
        ntypes = ['match', 'message', 'like', 'favorite']
        for u in users:
            for _ in range(random.randint(2, 8)):
                ntype = random.choice(ntypes)
                msgs = {
                    'match':    'You have a new match! 💕',
                    'message':  'You received a new message!',
                    'like':     'Someone liked your profile ❤️',
                    'favorite': 'Someone saved your profile ⭐',
                }
                n = Notification(
                    user_id=u.user_id, type=ntype,
                    message=msgs[ntype],
                    is_read=random.random() < 0.6,
                    created_at=random_dt(30)
                )
                db.session.add(n)
        db.session.commit()
        print('Notifications created.')

        print('\n✅ Seed complete!')
        print(f'   Users:   {User.query.count()}')
        print(f'   Matches: {Match.query.count()}')
        print(f'   Messages:{Message.query.count()}')
        print(f'\nTest account: test@driftdater.com / password123')
        print('All seed accounts: <username>@example.com / password123')


if __name__ == '__main__':
    run()
