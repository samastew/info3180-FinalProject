"""
SQLAlchemy ORM Models for DriftDater
"""
import enum
import math
from datetime import datetime, timezone
from app import db
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash


# ─────────────────────────────────────────────
# ENUM TYPES
# ─────────────────────────────────────────────

class SwipeAction(enum.Enum):
    like    = 'like'
    dislike = 'dislike'
    pass_   = 'pass'


class GenderType(enum.Enum):
    male       = 'male'
    female     = 'female'
    non_binary = 'non_binary'
    other      = 'other'


class LookingForType(enum.Enum):
    male       = 'male'
    female     = 'female'
    non_binary = 'non_binary'
    any        = 'any'


class RelationshipGoalType(enum.Enum):
    casual     = 'casual'
    serious    = 'serious'
    friendship = 'friendship'
    marriage   = 'marriage'


class EducationLevelType(enum.Enum):
    high_school = 'high_school'
    associate   = 'associate'
    bachelors   = 'bachelors'
    masters     = 'masters'
    phd         = 'phd'
    other       = 'other'


class MatchStatusType(enum.Enum):
    active    = 'active'
    archived  = 'archived'
    blocked   = 'blocked'
    unmatched = 'unmatched'


# ─────────────────────────────────────────────
# ASSOCIATION TABLE — User Interests
# ─────────────────────────────────────────────

user_interests = db.Table(
    'user_interests',
    db.Column('user_id',     db.Integer, db.ForeignKey('users.user_id',     ondelete='CASCADE'), primary_key=True),
    db.Column('interest_id', db.Integer, db.ForeignKey('interests.interest_id', ondelete='CASCADE'), primary_key=True)
)


# ─────────────────────────────────────────────
# USER
# ─────────────────────────────────────────────

class User(UserMixin, db.Model):
    __tablename__ = 'users'

    user_id                = db.Column(db.Integer, primary_key=True)
    username               = db.Column(db.String(50),  nullable=False, unique=True)
    email                  = db.Column(db.String(255), nullable=False, unique=True)
    password_hash          = db.Column(db.String(255), nullable=False)
    email_verified         = db.Column(db.Boolean, nullable=False, default=False)
    verification_token     = db.Column(db.String(255))
    password_reset_token   = db.Column(db.String(255))
    password_reset_expires = db.Column(db.DateTime(timezone=True))
    is_active              = db.Column(db.Boolean, nullable=False, default=True)
    last_seen_at           = db.Column(db.DateTime(timezone=True))
    created_at             = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at             = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                                       onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    profile  = db.relationship('Profile',      back_populates='user', uselist=False, cascade='all, delete-orphan')
    photos   = db.relationship('ProfilePhoto', back_populates='user', cascade='all, delete-orphan')
    interests = db.relationship('Interest',    secondary=user_interests, back_populates='users')

    sent_swipes     = db.relationship('Swipe', foreign_keys='Swipe.swiper_id', back_populates='swiper', cascade='all, delete-orphan')
    received_swipes = db.relationship('Swipe', foreign_keys='Swipe.swiped_id', back_populates='swiped', cascade='all, delete-orphan')

    matches_as_user1 = db.relationship('Match', foreign_keys='Match.user1_id', back_populates='user1', cascade='all, delete-orphan')
    matches_as_user2 = db.relationship('Match', foreign_keys='Match.user2_id', back_populates='user2', cascade='all, delete-orphan')

    sent_messages    = db.relationship('Message', back_populates='sender', cascade='all, delete-orphan')
    favorites_given  = db.relationship('Favorite', foreign_keys='Favorite.user_id',      back_populates='user',      cascade='all, delete-orphan')
    favorites_received = db.relationship('Favorite', foreign_keys='Favorite.favorited_id', back_populates='favorited', cascade='all, delete-orphan')
    notifications    = db.relationship('Notification', back_populates='user', cascade='all, delete-orphan')
    blocks_made      = db.relationship('UserBlock', foreign_keys='UserBlock.blocker_id', back_populates='blocker', cascade='all, delete-orphan')
    blocks_received  = db.relationship('UserBlock', foreign_keys='UserBlock.blocked_id', back_populates='blocked', cascade='all, delete-orphan')
    reports_made     = db.relationship('UserReport', foreign_keys='UserReport.reporter_id', back_populates='reporter', cascade='all, delete-orphan')
    reports_received = db.relationship('UserReport', foreign_keys='UserReport.reported_id', back_populates='reported', cascade='all, delete-orphan')

    # Flask-Login requires get_id() to return str
    def get_id(self):
        return str(self.user_id)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    @property
    def primary_photo(self):
        for p in self.photos:
            if p.is_primary:
                return p
        return self.photos[0] if self.photos else None

    def to_dict(self, include_private=False):
        d = {
            'user_id':    self.user_id,
            'username':   self.username,
            'is_active':  self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_seen_at': self.last_seen_at.isoformat() if self.last_seen_at else None,
            'photo': self.primary_photo.photo_url if self.primary_photo else None,
        }
        if include_private:
            d['email'] = self.email
            d['email_verified'] = self.email_verified
        return d


# ─────────────────────────────────────────────
# PROFILE
# ─────────────────────────────────────────────

class Profile(db.Model):
    __tablename__ = 'profiles'

    profile_id        = db.Column(db.Integer, primary_key=True)
    user_id           = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False, unique=True)

    first_name        = db.Column(db.String(50),  nullable=False)
    last_name         = db.Column(db.String(50),  nullable=False)
    date_of_birth     = db.Column(db.Date,        nullable=False)

    gender            = db.Column(db.Enum(GenderType,           native_enum=False),            nullable=False)
    bio               = db.Column(db.Text)
    city              = db.Column(db.String(100))
    country           = db.Column(db.String(100))
    latitude          = db.Column(db.Numeric(9, 6))
    longitude         = db.Column(db.Numeric(9, 6))

    looking_for       = db.Column(db.Enum(LookingForType,       native_enum=False),        nullable=False, default=LookingForType.any)
    min_age_pref      = db.Column(db.SmallInteger, nullable=False, default=18)
    max_age_pref      = db.Column(db.SmallInteger, nullable=False, default=99)
    max_distance_km   = db.Column(db.SmallInteger, nullable=False, default=50)

    occupation        = db.Column(db.String(100))
    education_level   = db.Column(db.Enum(EducationLevelType,   native_enum=False))
    relationship_goal = db.Column(db.Enum(RelationshipGoalType, native_enum=False))

    is_visible        = db.Column(db.Boolean, nullable=False, default=True)
    created_at        = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at        = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                                  onupdate=lambda: datetime.now(timezone.utc))

    user = db.relationship('User', back_populates='profile')

    @property
    def age(self):
        from datetime import date
        today = date.today()
        dob   = self.date_of_birth
        if dob is None:
            return None
        return today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))

    def distance_to(self, lat2, lon2):
        """Haversine distance in km."""
        if self.latitude is None or self.longitude is None:
            return None
        R = 6371
        lat1 = math.radians(float(self.latitude))
        lat2 = math.radians(lat2)
        dlat = lat2 - lat1
        dlon = math.radians(lon2 - float(self.longitude))
        a = math.sin(dlat/2)**2 + math.cos(lat1)*math.cos(lat2)*math.sin(dlon/2)**2
        return R * 2 * math.asin(math.sqrt(a))

    def to_dict(self):
        return {
            'profile_id':        self.profile_id,
            'user_id':           self.user_id,
            'first_name':        self.first_name,
            'last_name':         self.last_name,
            'date_of_birth':     self.date_of_birth.isoformat() if self.date_of_birth else None,
            'age':               self.age,
            'gender':            self.gender.value if self.gender else None,
            'bio':               self.bio,
            'city':              self.city,
            'country':           self.country,
            'latitude':          float(self.latitude) if self.latitude else None,
            'longitude':         float(self.longitude) if self.longitude else None,
            'looking_for':       self.looking_for.value if self.looking_for else None,
            'min_age_pref':      self.min_age_pref,
            'max_age_pref':      self.max_age_pref,
            'max_distance_km':   self.max_distance_km,
            'occupation':        self.occupation,
            'education_level':   self.education_level.value if self.education_level else None,
            'relationship_goal': self.relationship_goal.value if self.relationship_goal else None,
            'is_visible':        self.is_visible,
        }


# ─────────────────────────────────────────────
# INTEREST
# ─────────────────────────────────────────────

class Interest(db.Model):
    __tablename__ = 'interests'

    interest_id = db.Column(db.Integer, primary_key=True)
    name        = db.Column(db.String(100), nullable=False, unique=True)
    category    = db.Column(db.String(50))

    users = db.relationship('User', secondary=user_interests, back_populates='interests')

    def to_dict(self):
        return {'interest_id': self.interest_id, 'name': self.name, 'category': self.category}


# ─────────────────────────────────────────────
# PROFILE PHOTO
# ─────────────────────────────────────────────

class ProfilePhoto(db.Model):
    __tablename__ = 'profile_photos'

    photo_id    = db.Column(db.Integer, primary_key=True)
    user_id     = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    photo_url   = db.Column(db.String(500), nullable=False)
    is_primary  = db.Column(db.Boolean, nullable=False, default=False)
    uploaded_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at  = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                            onupdate=lambda: datetime.now(timezone.utc))

    user = db.relationship('User', back_populates='photos')

    def to_dict(self):
        return {
            'photo_id':   self.photo_id,
            'user_id':    self.user_id,
            'photo_url':  self.photo_url,
            'is_primary': self.is_primary,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None,
        }


# ─────────────────────────────────────────────
# SWIPE
# ─────────────────────────────────────────────

class Swipe(db.Model):
    __tablename__ = 'swipes'

    swipe_id   = db.Column(db.Integer, primary_key=True)
    swiper_id  = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    swiped_id  = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    action     = db.Column(db.Enum(SwipeAction,          native_enum=False), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        db.UniqueConstraint('swiper_id', 'swiped_id', name='swipes_unique_pair'),
        db.CheckConstraint('swiper_id <> swiped_id', name='swipes_no_self_swipe'),
    )

    swiper = db.relationship('User', foreign_keys=[swiper_id], back_populates='sent_swipes')
    swiped = db.relationship('User', foreign_keys=[swiped_id], back_populates='received_swipes')


# ─────────────────────────────────────────────
# MATCH
# ─────────────────────────────────────────────

class Match(db.Model):
    __tablename__ = 'matches'

    match_id   = db.Column(db.Integer, primary_key=True)
    user1_id   = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    user2_id   = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    status     = db.Column(db.Enum(MatchStatusType,      native_enum=False), nullable=False, default=MatchStatusType.active)
    matched_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        db.UniqueConstraint('user1_id', 'user2_id', name='matches_unique_pair'),
        db.CheckConstraint('user1_id <> user2_id', name='matches_no_self_match'),
        db.CheckConstraint('user1_id < user2_id',  name='matches_order_check'),
    )

    user1        = db.relationship('User', foreign_keys=[user1_id], back_populates='matches_as_user1')
    user2        = db.relationship('User', foreign_keys=[user2_id], back_populates='matches_as_user2')
    conversation = db.relationship('Conversation', back_populates='match', uselist=False, cascade='all, delete-orphan')

    def other_user(self, current_user_id):
        return self.user2 if self.user1_id == current_user_id else self.user1

    def to_dict(self, current_user_id=None):
        other = self.other_user(current_user_id) if current_user_id else None
        return {
            'match_id':   self.match_id,
            'user1_id':   self.user1_id,
            'user2_id':   self.user2_id,
            'status':     self.status.value,
            'matched_at': self.matched_at.isoformat() if self.matched_at else None,
            'other_user': other.to_dict() if other else None,
            'other_profile': other.profile.to_dict() if other and other.profile else None,
            'conversation_id': self.conversation.conversation_id if self.conversation else None,
        }


# ─────────────────────────────────────────────
# CONVERSATION
# ─────────────────────────────────────────────

class Conversation(db.Model):
    __tablename__ = 'conversations'

    conversation_id = db.Column(db.Integer, primary_key=True)
    match_id        = db.Column(db.Integer, db.ForeignKey('matches.match_id', ondelete='CASCADE'), nullable=False, unique=True)
    created_at      = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    match    = db.relationship('Match', back_populates='conversation')
    messages = db.relationship('Message', back_populates='conversation', cascade='all, delete-orphan',
                               order_by='Message.sent_at')

    def last_message(self):
        return self.messages[-1] if self.messages else None


# ─────────────────────────────────────────────
# MESSAGE
# ─────────────────────────────────────────────

class Message(db.Model):
    __tablename__ = 'messages'

    message_id      = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(db.Integer, db.ForeignKey('conversations.conversation_id', ondelete='CASCADE'), nullable=False)
    sender_id       = db.Column(db.Integer, db.ForeignKey('users.user_id',               ondelete='CASCADE'), nullable=False)
    body            = db.Column(db.Text, nullable=False)
    is_read         = db.Column(db.Boolean, nullable=False, default=False)
    sent_at         = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    conversation = db.relationship('Conversation', back_populates='messages')
    sender       = db.relationship('User',         back_populates='sent_messages')

    def to_dict(self):
        return {
            'message_id':      self.message_id,
            'conversation_id': self.conversation_id,
            'sender_id':       self.sender_id,
            'body':            self.body,
            'is_read':         self.is_read,
            'sent_at':         self.sent_at.isoformat() if self.sent_at else None,
        }


# ─────────────────────────────────────────────
# FAVORITE
# ─────────────────────────────────────────────

class Favorite(db.Model):
    __tablename__ = 'favorites'

    user_id      = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), primary_key=True)
    favorited_id = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), primary_key=True)
    created_at   = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at   = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc),
                             onupdate=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        db.CheckConstraint('user_id <> favorited_id', name='favorites_no_self'),
    )

    user      = db.relationship('User', foreign_keys=[user_id],      back_populates='favorites_given')
    favorited = db.relationship('User', foreign_keys=[favorited_id], back_populates='favorites_received')


# ─────────────────────────────────────────────
# NOTIFICATION
# ─────────────────────────────────────────────

class Notification(db.Model):
    __tablename__ = 'notifications'

    notification_id = db.Column(db.Integer, primary_key=True)
    user_id         = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    type            = db.Column(db.String(50), nullable=False)
    message         = db.Column(db.Text, nullable=False)
    is_read         = db.Column(db.Boolean, nullable=False, default=False)
    created_at      = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = db.relationship('User', back_populates='notifications')

    def to_dict(self):
        return {
            'notification_id': self.notification_id,
            'user_id':         self.user_id,
            'type':            self.type,
            'message':         self.message,
            'is_read':         self.is_read,
            'created_at':      self.created_at.isoformat() if self.created_at else None,
        }


# ─────────────────────────────────────────────
# USER BLOCK
# ─────────────────────────────────────────────

class UserBlock(db.Model):
    __tablename__ = 'user_blocks'

    blocker_id = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), primary_key=True)
    blocked_id = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), primary_key=True)
    created_at = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        db.CheckConstraint('blocker_id <> blocked_id', name='blocks_no_self'),
    )

    blocker = db.relationship('User', foreign_keys=[blocker_id], back_populates='blocks_made')
    blocked = db.relationship('User', foreign_keys=[blocked_id], back_populates='blocks_received')


# ─────────────────────────────────────────────
# USER REPORT
# ─────────────────────────────────────────────

class UserReport(db.Model):
    __tablename__ = 'user_reports'

    report_id   = db.Column(db.Integer, primary_key=True)
    reporter_id = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    reported_id = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    reason      = db.Column(db.Text, nullable=False)
    created_at  = db.Column(db.DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        db.CheckConstraint('reporter_id <> reported_id', name='reports_no_self'),
    )

    reporter = db.relationship('User', foreign_keys=[reporter_id], back_populates='reports_made')
    reported = db.relationship('User', foreign_keys=[reported_id], back_populates='reports_received')
