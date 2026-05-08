import os
from dotenv import load_dotenv
load_dotenv()

from app import create_app, db
from app.models import Interest

INTERESTS = [
    ('Hiking','outdoors'),('Camping','outdoors'),('Cycling','outdoors'),
    ('Swimming','outdoors'),('Beach','outdoors'),('Fishing','outdoors'),
    ('Photography','arts'),('Painting','arts'),('Drawing','arts'),
    ('Writing','arts'),('Poetry','arts'),('Dancing','arts'),
    ('Coding','tech'),('Gaming','tech'),('Gadgets','tech'),
    ('Cooking','food'),('Baking','food'),('Foodie','food'),
    ('Coffee','food'),('Wine','food'),
    ('Travel','travel'),('Road Trips','travel'),('Backpacking','travel'),
    ('Music','music'),('Concerts','music'),('Singing','music'),
    ('Playing Guitar','music'),
    ('Reading','education'),('History','education'),('Science','education'),
    ('Languages','education'),
    ('Football','sports'),('Basketball','sports'),('Tennis','sports'),
    ('Yoga','sports'),('Gym / Fitness','sports'),('Running','sports'),
    ('Cricket','sports'),
    ('Movies','entertainment'),('TV Shows','entertainment'),
    ('Anime','entertainment'),('Comedy','entertainment'),
    ('Meditation','wellness'),('Mental Health','wellness'),
    ('Volunteering','social'),('Board Games','social'),('Pets','social'),
]

def seed():
    app = create_app()
    with app.app_context():
        added = 0
        for name, category in INTERESTS:
            if not Interest.query.filter_by(name=name).first():
                db.session.add(Interest(name=name, category=category))
                added += 1
        db.session.commit()
        total = Interest.query.count()
        print(f"Done. Added {added} new interests. Total in DB: {total}")

if __name__ == '__main__':
    seed()
