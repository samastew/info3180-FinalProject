from . import db
from datetime import datetime, date
from werkzeug.security import generate_password_hash, check_password_hash as werkzeug_check

# ─────────────────────────────────────────────────────────────────────────────
# ASSOCIATION TABLE  (must be first — models below reference it)
# Links users.user_id ↔ interests.interest_id
# ─────────────────────────────────────────────────────────────────────────────
user_interests = db.Table(
    'user_interests',
    db.Column('user_id',     db.Integer,
              db.ForeignKey('users.user_id',          ondelete='CASCADE'), primary_key=True),
    db.Column('interest_id', db.Integer,
              db.ForeignKey('interests.interest_id',  ondelete='CASCADE'), primary_key=True),
)


# ─────────────────────────────────────────────────────────────────────────────
# INTEREST  (before User so the relationship in User resolves cleanly)
# ─────────────────────────────────────────────────────────────────────────────
class Interest(db.Model):
    __tablename__ = 'interests'
    interest_id = db.Column(db.Integer, primary_key=True)
    name        = db.Column(db.String(100), nullable=False, unique=True)
    category    = db.Column(db.String(50))

    def to_dict(self):
        return {'interest_id': self.interest_id, 'name': self.name, 'category': self.category}


# ─────────────────────────────────────────────────────────────────────────────
# USER
# ─────────────────────────────────────────────────────────────────────────────
class User(db.Model):
    __tablename__ = 'users'
    user_id       = db.Column(db.Integer, primary_key=True)
    username      = db.Column(db.String(50),  nullable=False, unique=True)
    email         = db.Column(db.String(255), nullable=False, unique=True)
    password_hash = db.Column(db.String(255), nullable=False)
    is_active     = db.Column(db.Boolean,     nullable=False, default=True)
    created_at    = db.Column(db.DateTime(timezone=True), nullable=False, default=datetime.utcnow)
    updated_at    = db.Column(db.DateTime(timezone=True), nullable=False,
                              default=datetime.utcnow, onupdate=datetime.utcnow)

    profile         = db.relationship('Profile',      back_populates='user',
                                      uselist=False, cascade='all, delete-orphan')
    swipes_made     = db.relationship('Swipe',        foreign_keys='Swipe.swiper_id',
                                      back_populates='swiper', cascade='all, delete-orphan')
    swipes_received = db.relationship('Swipe',        foreign_keys='Swipe.swiped_id',
                                      back_populates='swiped', cascade='all, delete-orphan')
    favorites       = db.relationship('Favorite',     foreign_keys='Favorite.user_id',
                                      back_populates='user',   cascade='all, delete-orphan')
    photos          = db.relationship('ProfilePhoto', back_populates='user',
                                      cascade='all, delete-orphan')
    messages_sent   = db.relationship('Message',      back_populates='sender',
                                      cascade='all, delete-orphan')

    # Many-to-many: user_interests.user_id == users.user_id (explicit joins)
    interests = db.relationship(
        'Interest',
        secondary=user_interests,
        primaryjoin=lambda: User.user_id == user_interests.c.user_id,
        secondaryjoin=lambda: user_interests.c.interest_id == Interest.interest_id,
        lazy='subquery',
    )

    def set_password(self, password):
        # werkzeug generates pbkdf2:sha256:... format
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        h = self.password_hash or ""
        # Seed data was generated with raw bcrypt ($2b$...).
        # New registrations use werkzeug (pbkdf2:sha256:...).
        # Support both so existing seeded accounts can log in.
        if h.startswith("$2b$") or h.startswith("$2a$"):
            try:
                import bcrypt
                return bcrypt.checkpw(password.encode("utf-8"), h.encode("utf-8"))
            except Exception:
                return False
        return werkzeug_check(h, password)

    def to_dict(self):
        return {
            'user_id':    self.user_id,
            'username':   self.username,
            'email':      self.email,
            'is_active':  self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


# ─────────────────────────────────────────────────────────────────────────────
# PROFILE
# ─────────────────────────────────────────────────────────────────────────────
class Profile(db.Model):
    __tablename__ = 'profiles'
    profile_id        = db.Column(db.Integer, primary_key=True)
    user_id           = db.Column(db.Integer,
                                  db.ForeignKey('users.user_id', ondelete='CASCADE'),
                                  nullable=False, unique=True)
    first_name        = db.Column(db.String(50),   nullable=False)
    last_name         = db.Column(db.String(50),   nullable=False)
    date_of_birth     = db.Column(db.Date,         nullable=False)
    gender            = db.Column(db.String(20),   nullable=False)
    bio               = db.Column(db.Text)
    profile_photo_url = db.Column(db.String(500))
    city              = db.Column(db.String(100))
    country           = db.Column(db.String(100))
    latitude          = db.Column(db.Numeric(9, 6))
    longitude         = db.Column(db.Numeric(9, 6))
    looking_for       = db.Column(db.String(20),   nullable=False, default='any')
    min_age_pref      = db.Column(db.SmallInteger, nullable=False, default=18)
    max_age_pref      = db.Column(db.SmallInteger, nullable=False, default=99)
    max_distance_km   = db.Column(db.SmallInteger, nullable=False, default=50)
    occupation        = db.Column(db.String(100))
    education_level   = db.Column(db.String(50))
    relationship_goal = db.Column(db.String(50))
    is_visible        = db.Column(db.Boolean,      nullable=False, default=True)
    created_at        = db.Column(db.DateTime(timezone=True), nullable=False, default=datetime.utcnow)
    updated_at        = db.Column(db.DateTime(timezone=True), nullable=False,
                                  default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship('User', back_populates='profile')

    @property
    def age(self):
        if self.date_of_birth:
            today = date.today()
            dob   = self.date_of_birth
            return (today.year - dob.year
                    - ((today.month, today.day) < (dob.month, dob.day)))
        return None

    @property
    def interests(self):
        """user_interests is keyed on users.user_id, so delegate through User."""
        return self.user.interests if self.user else []

    def to_dict(self, include_user=False):
        d = {
            'profile_id':        self.profile_id,
            'user_id':           self.user_id,
            'first_name':        self.first_name,
            'last_name':         self.last_name,
            'age':               self.age,
            'gender':            self.gender,
            'bio':               self.bio,
            'profile_photo_url': self.profile_photo_url,
            'city':              self.city,
            'country':           self.country,
            'looking_for':       self.looking_for,
            'min_age_pref':      self.min_age_pref,
            'max_age_pref':      self.max_age_pref,
            'max_distance_km':   self.max_distance_km,
            'occupation':        self.occupation,
            'education_level':   self.education_level,
            'relationship_goal': self.relationship_goal,
            'is_visible':        self.is_visible,
            'interests': [
                {'interest_id': i.interest_id, 'name': i.name, 'category': i.category}
                for i in self.interests
            ],
        }
        if include_user and self.user:
            d['username'] = self.user.username
        return d


# ─────────────────────────────────────────────────────────────────────────────
# SWIPE
# ─────────────────────────────────────────────────────────────────────────────
class Swipe(db.Model):
    __tablename__ = 'swipes'
    swipe_id   = db.Column(db.Integer, primary_key=True)
    swiper_id  = db.Column(db.Integer,
                           db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    swiped_id  = db.Column(db.Integer,
                           db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    action     = db.Column(db.String(10), nullable=False)   # 'like' | 'dislike' | 'pass'
    created_at = db.Column(db.DateTime(timezone=True), nullable=False, default=datetime.utcnow)

    swiper = db.relationship('User', foreign_keys=[swiper_id], back_populates='swipes_made')
    swiped = db.relationship('User', foreign_keys=[swiped_id], back_populates='swipes_received')

    __table_args__ = (
        db.UniqueConstraint('swiper_id', 'swiped_id', name='swipes_unique_pair'),
        db.CheckConstraint('swiper_id <> swiped_id',  name='swipes_no_self_swipe'),
    )


# ─────────────────────────────────────────────────────────────────────────────
# MATCH
# ─────────────────────────────────────────────────────────────────────────────
class Match(db.Model):
    __tablename__ = 'matches'
    match_id   = db.Column(db.Integer, primary_key=True)
    user1_id   = db.Column(db.Integer,
                           db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    user2_id   = db.Column(db.Integer,
                           db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    matched_at = db.Column(db.DateTime(timezone=True), nullable=False, default=datetime.utcnow)

    user1        = db.relationship('User', foreign_keys=[user1_id])
    user2        = db.relationship('User', foreign_keys=[user2_id])
    conversation = db.relationship('Conversation', back_populates='match',
                                   uselist=False, cascade='all, delete-orphan')

    __table_args__ = (
        db.CheckConstraint('user1_id <> user2_id', name='matches_no_self_match'),
    )

    def other_user(self, current_user_id):
        return self.user2 if self.user1_id == current_user_id else self.user1

    def to_dict(self, current_user_id=None):
        other = self.other_user(current_user_id) if current_user_id else None
        d = {
            'match_id':   self.match_id,
            'user1_id':   self.user1_id,
            'user2_id':   self.user2_id,
            'matched_at': self.matched_at.isoformat() if self.matched_at else None,
        }
        if other and other.profile:
            d['other_profile'] = other.profile.to_dict()
        return d


# ─────────────────────────────────────────────────────────────────────────────
# CONVERSATION
# ─────────────────────────────────────────────────────────────────────────────
class Conversation(db.Model):
    __tablename__ = 'conversations'
    conversation_id = db.Column(db.Integer, primary_key=True)
    match_id        = db.Column(db.Integer,
                                db.ForeignKey('matches.match_id', ondelete='CASCADE'),
                                nullable=False, unique=True)
    created_at      = db.Column(db.DateTime(timezone=True), nullable=False, default=datetime.utcnow)

    match    = db.relationship('Match', back_populates='conversation')
    messages = db.relationship('Message', back_populates='conversation',
                               order_by='Message.sent_at', cascade='all, delete-orphan')


# ─────────────────────────────────────────────────────────────────────────────
# MESSAGE
# ─────────────────────────────────────────────────────────────────────────────
class Message(db.Model):
    __tablename__ = 'messages'
    message_id      = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(db.Integer,
                                db.ForeignKey('conversations.conversation_id', ondelete='CASCADE'),
                                nullable=False)
    sender_id       = db.Column(db.Integer,
                                db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    body            = db.Column(db.Text,    nullable=False)
    is_read         = db.Column(db.Boolean, nullable=False, default=False)
    sent_at         = db.Column(db.DateTime(timezone=True), nullable=False, default=datetime.utcnow)

    conversation = db.relationship('Conversation', back_populates='messages')
    sender       = db.relationship('User',         back_populates='messages_sent')

    def to_dict(self):
        return {
            'message_id':      self.message_id,
            'conversation_id': self.conversation_id,
            'sender_id':       self.sender_id,
            'body':            self.body,
            'is_read':         self.is_read,
            'sent_at':         self.sent_at.isoformat() if self.sent_at else None,
        }


# ─────────────────────────────────────────────────────────────────────────────
# FAVORITE
# ─────────────────────────────────────────────────────────────────────────────
class Favorite(db.Model):
    __tablename__ = 'favorites'
    user_id      = db.Column(db.Integer,
                             db.ForeignKey('users.user_id', ondelete='CASCADE'), primary_key=True)
    favorited_id = db.Column(db.Integer,
                             db.ForeignKey('users.user_id', ondelete='CASCADE'), primary_key=True)
    created_at   = db.Column(db.DateTime(timezone=True), nullable=False, default=datetime.utcnow)

    user      = db.relationship('User', foreign_keys=[user_id],      back_populates='favorites')
    favorited = db.relationship('User', foreign_keys=[favorited_id])

    __table_args__ = (
        db.CheckConstraint('user_id <> favorited_id', name='favorites_no_self'),
    )


# ─────────────────────────────────────────────────────────────────────────────
# PROFILE PHOTO
# ─────────────────────────────────────────────────────────────────────────────
class ProfilePhoto(db.Model):
    __tablename__ = 'profile_photos'
    photo_id    = db.Column(db.Integer, primary_key=True)
    user_id     = db.Column(db.Integer,
                            db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    photo_url   = db.Column(db.String(500), nullable=False)
    is_primary  = db.Column(db.Boolean,     nullable=False, default=False)
    uploaded_at = db.Column(db.DateTime(timezone=True), nullable=False, default=datetime.utcnow)

    user = db.relationship('User', back_populates='photos')

    def to_dict(self):
        return {
            'photo_id':    self.photo_id,
            'user_id':     self.user_id,
            'photo_url':   self.photo_url,
            'is_primary':  self.is_primary,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None,
        }
