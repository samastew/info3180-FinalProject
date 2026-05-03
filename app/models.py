from app import db
from datetime import datetime

# Many-to-many: users <-> interests
user_interests = db.Table('user_interests',
    db.Column('user_id', db.Integer, db.ForeignKey('users.id'), primary_key=True),
    db.Column('interest_id', db.Integer, db.ForeignKey('interests.id'), primary_key=True)
)

class User(db.Model):
    __tablename__ = 'users'

    id             = db.Column(db.Integer, primary_key=True)
    name           = db.Column(db.String(160), nullable=False)
    email          = db.Column(db.String(255), unique=True, nullable=False, index=True)
    password_hash  = db.Column(db.String(255), nullable=False)
    age            = db.Column(db.Integer)
    bio            = db.Column(db.Text)
    occupation     = db.Column(db.String(120))
    city           = db.Column(db.String(120))
    latitude       = db.Column(db.Float)
    longitude      = db.Column(db.Float)
    looking_for    = db.Column(db.String(80))
    pref_min_age   = db.Column(db.Integer, default=18)
    pref_max_age   = db.Column(db.Integer, default=60)
    max_distance_km= db.Column(db.Integer, default=50)
    profile_picture= db.Column(db.String(255))
    is_public      = db.Column(db.Boolean, default=True)
    created_at     = db.Column(db.DateTime, default=datetime.utcnow, index=True)

    interests = db.relationship('Interest', secondary=user_interests, backref='users', lazy='joined')

    def to_dict(self):
        return {
            'id':             self.id,
            'name':           self.name,
            'age':            self.age,
            'bio':            self.bio,
            'occupation':     self.occupation,
            'city':           self.city,
            'latitude':       self.latitude,
            'longitude':      self.longitude,
            'interests':      [i.name for i in self.interests],
            'profile_picture':self.profile_picture,
            'looking_for':    self.looking_for,
            'pref_min_age':   self.pref_min_age,
            'pref_max_age':   self.pref_max_age,
            'max_distance_km':self.max_distance_km,
            'is_public':      self.is_public,
        }


class Interest(db.Model):
    __tablename__ = 'interests'

    id   = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)


class Interaction(db.Model):
    __tablename__ = 'interactions'

    id          = db.Column(db.Integer, primary_key=True)
    actor_id    = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    target_id   = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    action      = db.Column(db.String(20), nullable=False)  # 'like', 'dislike', 'pass'
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)


class Match(db.Model):
    __tablename__ = 'matches'

    id         = db.Column(db.Integer, primary_key=True)
    user1_id   = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    user2_id   = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class Message(db.Model):
    __tablename__ = 'messages'

    id          = db.Column(db.Integer, primary_key=True)
    sender_id   = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    receiver_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    body        = db.Column(db.Text, nullable=False)
    created_at  = db.Column(db.DateTime, default=datetime.utcnow, index=True)