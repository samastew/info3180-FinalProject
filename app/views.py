"""
DriftDater REST API
"""

import os
import uuid
from flask import Blueprint, jsonify, request, current_app, send_from_directory
from flask_jwt_extended import (
    create_access_token, jwt_required, get_jwt_identity
)
from werkzeug.utils import secure_filename
from sqlalchemy import or_, and_, func

from . import db
from .models import (
    User, Profile, Interest, Swipe, Match,
    Conversation, Message, Favorite, ProfilePhoto
)

bp = Blueprint('api', __name__, url_prefix='/api')

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}


# ─── ROOT & HEALTH CHECK ─────────────────────────────────────────────────────

@bp.route('/', methods=['GET'])
def api_root():
    """Friendly confirmation the API is running."""
    return jsonify(
        status='ok',
        message='DriftDater API is running 💕',
        version='1.0.0',
        endpoints={
            'register':      'POST /api/auth/register',
            'login':         'POST /api/auth/login',
            'logout':        'POST /api/auth/logout',
            'me':            'GET  /api/me',
            'discover':      'GET  /api/discover',
            'swipe':         'POST /api/swipes',
            'matches':       'GET  /api/matches',
            'conversations': 'GET  /api/conversations',
            'favorites':     'GET  /api/favorites',
            'interests':     'GET  /api/interests',
            'search':        'GET  /api/profiles/search',
        }
    ), 200


@bp.route('/health', methods=['GET'])
def health_check():
    """Database connectivity check."""
    try:
        db.session.execute(db.text('SELECT 1'))
        return jsonify(status='ok', database='connected'), 200
    except Exception as e:
        return jsonify(status='error', database='disconnected', detail=str(e)), 500


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def form_errors(errors):
    return [f"Error in the {field} field - {', '.join(msgs)}" for field, msgs in errors.items()]


# ─── AUTH ────────────────────────────────────────────────────────────────────

@bp.route('/auth/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    errors = {}

    for field in ['username', 'email', 'password']:
        if not data.get(field):
            errors[field] = ['This field is required.']

    if errors:
        return jsonify(errors=form_errors(errors)), 422

    if User.query.filter_by(username=data['username']).first():
        return jsonify(errors=['Username already taken.']), 409
    if User.query.filter_by(email=data['email']).first():
        return jsonify(errors=['Email already registered.']), 409

    user = User(username=data['username'], email=data['email'])
    user.set_password(data['password'])
    db.session.add(user)
    db.session.commit()

    token = create_access_token(identity=str(user.user_id))
    return jsonify(message='Registration successful.', token=token, user=user.to_dict()), 201


@bp.route('/auth/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = data.get('username', '').strip()
    password = data.get('password', '')

    user = User.query.filter_by(username=username).first()
    if not user or not user.check_password(password):
        return jsonify(errors=['Invalid username or password.']), 401

    token = create_access_token(identity=str(user.user_id))
    return jsonify(message='Login successful.', token=token, user=user.to_dict()), 200


@bp.route('/auth/logout', methods=['POST'])
@jwt_required()
def logout():
    return jsonify(message='Logged out successfully.'), 200


# ─── PROFILES ────────────────────────────────────────────────────────────────

@bp.route('/profiles', methods=['POST'])
@jwt_required()
def create_profile():
    current_user_id = int(get_jwt_identity())
    user = User.query.get_or_404(current_user_id)

    if user.profile:
        return jsonify(errors=['Profile already exists.']), 409

    data = request.get_json() or {}
    required = ['first_name', 'last_name', 'date_of_birth', 'gender']
    errors = {}
    for f in required:
        if not data.get(f):
            errors[f] = ['This field is required.']
    if errors:
        return jsonify(errors=form_errors(errors)), 422

    try:
        from datetime import date as date_type
        dob = date_type.fromisoformat(data['date_of_birth'])
    except ValueError:
        return jsonify(errors=['Invalid date format. Use YYYY-MM-DD.']), 422

    profile = Profile(
        user_id           = current_user_id,
        first_name        = data['first_name'],
        last_name         = data['last_name'],
        date_of_birth     = dob,
        gender            = data['gender'],
        bio               = data.get('bio'),
        city              = data.get('city'),
        country           = data.get('country'),
        looking_for       = data.get('looking_for', 'any'),
        min_age_pref      = data.get('min_age_pref', 18),
        max_age_pref      = data.get('max_age_pref', 99),
        max_distance_km   = data.get('max_distance_km', 50),
        occupation        = data.get('occupation'),
        education_level   = data.get('education_level'),
        relationship_goal = data.get('relationship_goal'),
        is_visible        = data.get('is_visible', True),
    )

    # Attach interests (at least 3)
    interest_ids = data.get('interest_ids', [])
    if len(interest_ids) < 3:
        return jsonify(errors=['Please select at least 3 interests.']), 422
    interests = Interest.query.filter(Interest.interest_id.in_(interest_ids)).all()
    user.interests = interests

    db.session.add(profile)
    db.session.commit()
    return jsonify(message='Profile created.', profile=profile.to_dict()), 201


@bp.route('/profiles/<int:user_id>', methods=['GET'])
@jwt_required()
def get_profile(user_id):
    user = User.query.get_or_404(user_id)
    if not user.profile:
        return jsonify(errors=['Profile not found.']), 404
    return jsonify(profile=user.profile.to_dict(include_user=True)), 200


@bp.route('/profiles/<int:user_id>', methods=['PUT'])
@jwt_required()
def update_profile(user_id):
    current_user_id = int(get_jwt_identity())
    if current_user_id != user_id:
        return jsonify(errors=['Unauthorized.']), 403

    user = User.query.get_or_404(user_id)
    if not user.profile:
        return jsonify(errors=['Profile not found.']), 404

    data = request.get_json() or {}
    profile = user.profile

    updatable = [
        'first_name', 'last_name', 'bio', 'city', 'country',
        'looking_for', 'min_age_pref', 'max_age_pref', 'max_distance_km',
        'occupation', 'education_level', 'relationship_goal', 'is_visible', 'gender'
    ]
    for field in updatable:
        if field in data:
            setattr(profile, field, data[field])

    if 'date_of_birth' in data:
        from datetime import date as date_type
        try:
            profile.date_of_birth = date_type.fromisoformat(data['date_of_birth'])
        except ValueError:
            return jsonify(errors=['Invalid date format.']), 422

    if 'interest_ids' in data:
        if len(data['interest_ids']) < 3:
            return jsonify(errors=['Please select at least 3 interests.']), 422
        interests = Interest.query.filter(Interest.interest_id.in_(data['interest_ids'])).all()
        user.interests = interests

    db.session.commit()
    return jsonify(message='Profile updated.', profile=profile.to_dict()), 200


@bp.route('/me', methods=['GET'])
@jwt_required()
def get_me():
    current_user_id = int(get_jwt_identity())
    user = User.query.get_or_404(current_user_id)
    result = user.to_dict()
    if user.profile:
        result['profile'] = user.profile.to_dict(include_user=True)
    return jsonify(user=result), 200


# ─── PHOTOS ──────────────────────────────────────────────────────────────────

@bp.route('/profiles/<int:user_id>/photos', methods=['POST'])
@jwt_required()
def upload_photo(user_id):
    current_user_id = int(get_jwt_identity())
    if current_user_id != user_id:
        return jsonify(errors=['Unauthorized.']), 403

    if 'photo' not in request.files:
        return jsonify(errors=['No file uploaded.']), 422

    file = request.files['photo']
    if file.filename == '' or not allowed_file(file.filename):
        return jsonify(errors=['Invalid file type.']), 422

    upload_folder = current_app.config.get('UPLOAD_FOLDER', 'uploads')
    os.makedirs(upload_folder, exist_ok=True)

    ext = file.filename.rsplit('.', 1)[1].lower()
    filename = f"{uuid.uuid4().hex}.{ext}"
    file.save(os.path.join(upload_folder, filename))

    photo_url = f"/api/uploads/{filename}"
    is_primary = request.form.get('is_primary', 'false').lower() == 'true'

    photo = ProfilePhoto(user_id=user_id, photo_url=photo_url, is_primary=is_primary)
    db.session.add(photo)

    # Update profile_photo_url if primary
    if is_primary and User.query.get(user_id).profile:
        User.query.get(user_id).profile.profile_photo_url = photo_url

    db.session.commit()
    return jsonify(message='Photo uploaded.', photo=photo.to_dict()), 201


@bp.route('/uploads/<path:filename>', methods=['GET'])
def serve_upload(filename):
    upload_folder = current_app.config.get('UPLOAD_FOLDER', 'uploads')
    return send_from_directory(upload_folder, filename)


# ─── INTERESTS ───────────────────────────────────────────────────────────────

@bp.route('/interests', methods=['GET'])
@jwt_required()
def list_interests():
    interests = Interest.query.order_by(Interest.category, Interest.name).all()
    return jsonify(interests=[i.to_dict() for i in interests]), 200


# ─── DISCOVER (Browse profiles) ──────────────────────────────────────────────

@bp.route('/discover', methods=['GET'])
@jwt_required()
def discover():
    current_user_id = int(get_jwt_identity())
    user = User.query.get_or_404(current_user_id)

    # Get IDs already swiped by current user
    swiped_ids = db.session.query(Swipe.swiped_id).filter_by(swiper_id=current_user_id).subquery()

    query = (
        db.session.query(Profile)
        .join(User, Profile.user_id == User.user_id)
        .filter(
            Profile.user_id != current_user_id,
            Profile.is_visible == True,
            User.is_active == True,
            ~Profile.user_id.in_(swiped_ids),
        )
    )

    profiles = query.order_by(func.random()).limit(20).all()
    return jsonify(profiles=[p.to_dict(include_user=True) for p in profiles]), 200


# ─── SWIPES ──────────────────────────────────────────────────────────────────

@bp.route('/swipes', methods=['POST'])
@jwt_required()
def create_swipe():
    current_user_id = int(get_jwt_identity())
    data = request.get_json() or {}

    swiped_id = data.get('swiped_id')
    action    = data.get('action')  # 'like', 'dislike', 'pass'

    if not swiped_id or action not in ('like', 'dislike', 'pass'):
        return jsonify(errors=['swiped_id and valid action are required.']), 422

    if swiped_id == current_user_id:
        return jsonify(errors=['Cannot swipe on yourself.']), 422

    # Check if already swiped
    existing = Swipe.query.filter_by(swiper_id=current_user_id, swiped_id=swiped_id).first()
    if existing:
        return jsonify(errors=['Already swiped on this user.']), 409

    swipe = Swipe(swiper_id=current_user_id, swiped_id=swiped_id, action=action)
    db.session.add(swipe)
    db.session.flush()

    matched = False
    match   = None

    # Check for mutual like
    if action == 'like':
        mutual = Swipe.query.filter_by(swiper_id=swiped_id, swiped_id=current_user_id, action='like').first()
        if mutual:
            # Create match (ensure user1_id < user2_id for uniqueness)
            u1, u2 = sorted([current_user_id, swiped_id])
            existing_match = Match.query.filter_by(user1_id=u1, user2_id=u2).first()
            if not existing_match:
                match = Match(user1_id=u1, user2_id=u2)
                db.session.add(match)
                db.session.flush()

                convo = Conversation(match_id=match.match_id)
                db.session.add(convo)
                matched = True
                match = match.to_dict(current_user_id=current_user_id)

    db.session.commit()
    return jsonify(message='Swipe recorded.', matched=matched, match=match), 201


# ─── MATCHES ─────────────────────────────────────────────────────────────────

@bp.route('/matches', methods=['GET'])
@jwt_required()
def list_matches():
    current_user_id = int(get_jwt_identity())
    matches = Match.query.filter(
        or_(Match.user1_id == current_user_id, Match.user2_id == current_user_id)
    ).order_by(Match.matched_at.desc()).all()

    return jsonify(matches=[m.to_dict(current_user_id=current_user_id) for m in matches]), 200


# ─── CONVERSATIONS & MESSAGES ─────────────────────────────────────────────────

@bp.route('/conversations', methods=['GET'])
@jwt_required()
def list_conversations():
    current_user_id = int(get_jwt_identity())
    matches = Match.query.filter(
        or_(Match.user1_id == current_user_id, Match.user2_id == current_user_id)
    ).all()

    result = []
    for m in matches:
        if not m.conversation:
            continue
        other = m.other_user(current_user_id)
        last_msg = m.conversation.messages[-1] if m.conversation.messages else None
        unread   = sum(1 for msg in m.conversation.messages if not msg.is_read and msg.sender_id != current_user_id)
        result.append({
            'conversation_id': m.conversation.conversation_id,
            'match_id':        m.match_id,
            'other_user_id':   other.user_id,
            'other_name':      f"{other.profile.first_name} {other.profile.last_name}" if other.profile else other.username,
            'other_photo':     other.profile.profile_photo_url if other.profile else None,
            'last_message':    last_msg.body if last_msg else None,
            'last_message_at': last_msg.sent_at.isoformat() if last_msg else None,
            'unread_count':    unread,
        })

    result.sort(key=lambda x: x['last_message_at'] or '', reverse=True)
    return jsonify(conversations=result), 200


@bp.route('/conversations/<int:conversation_id>/messages', methods=['GET'])
@jwt_required()
def get_messages(conversation_id):
    current_user_id = int(get_jwt_identity())
    convo = Conversation.query.get_or_404(conversation_id)
    match = convo.match

    if match.user1_id != current_user_id and match.user2_id != current_user_id:
        return jsonify(errors=['Unauthorized.']), 403

    # Mark messages as read
    for msg in convo.messages:
        if msg.sender_id != current_user_id and not msg.is_read:
            msg.is_read = True
    db.session.commit()

    return jsonify(messages=[m.to_dict() for m in convo.messages]), 200


@bp.route('/conversations/<int:conversation_id>/messages', methods=['POST'])
@jwt_required()
def send_message(conversation_id):
    current_user_id = int(get_jwt_identity())
    convo = Conversation.query.get_or_404(conversation_id)
    match = convo.match

    if match.user1_id != current_user_id and match.user2_id != current_user_id:
        return jsonify(errors=['Unauthorized.']), 403

    data = request.get_json() or {}
    body = data.get('body', '').strip()
    if not body:
        return jsonify(errors=['Message body cannot be empty.']), 422

    msg = Message(conversation_id=conversation_id, sender_id=current_user_id, body=body)
    db.session.add(msg)
    db.session.commit()
    return jsonify(message='Message sent.', data=msg.to_dict()), 201


# ─── FAVORITES ───────────────────────────────────────────────────────────────

@bp.route('/favorites', methods=['GET'])
@jwt_required()
def list_favorites():
    current_user_id = int(get_jwt_identity())
    favs = Favorite.query.filter_by(user_id=current_user_id).all()
    result = []
    for f in favs:
        u = f.favorited
        if u and u.profile:
            result.append({
                'favorited_id': f.favorited_id,
                'profile': u.profile.to_dict(include_user=True),
                'created_at': f.created_at.isoformat(),
            })
    return jsonify(favorites=result), 200


@bp.route('/favorites/<int:favorited_id>', methods=['POST'])
@jwt_required()
def add_favorite(favorited_id):
    current_user_id = int(get_jwt_identity())
    if current_user_id == favorited_id:
        return jsonify(errors=['Cannot favorite yourself.']), 422

    existing = Favorite.query.filter_by(user_id=current_user_id, favorited_id=favorited_id).first()
    if existing:
        return jsonify(errors=['Already in favorites.']), 409

    fav = Favorite(user_id=current_user_id, favorited_id=favorited_id)
    db.session.add(fav)
    db.session.commit()
    return jsonify(message='Added to favorites.'), 201


@bp.route('/favorites/<int:favorited_id>', methods=['DELETE'])
@jwt_required()
def remove_favorite(favorited_id):
    current_user_id = int(get_jwt_identity())
    fav = Favorite.query.filter_by(user_id=current_user_id, favorited_id=favorited_id).first()
    if not fav:
        return jsonify(errors=['Not in favorites.']), 404
    db.session.delete(fav)
    db.session.commit()
    return jsonify(message='Removed from favorites.'), 200


# ─── SEARCH ──────────────────────────────────────────────────────────────────

@bp.route('/profiles/search', methods=['GET'])
@jwt_required()
def search_profiles():
    current_user_id = int(get_jwt_identity())

    name         = request.args.get('name',   '').strip()
    city         = request.args.get('city',   '').strip()
    gender       = request.args.get('gender', '').strip()
    min_age      = request.args.get('min_age', type=int)
    max_age      = request.args.get('max_age', type=int)
    interest_ids = request.args.getlist('interest_ids', type=int)

    query = (
        db.session.query(Profile)
        .join(User, Profile.user_id == User.user_id)
        .filter(
            Profile.user_id != current_user_id,
            Profile.is_visible == True,
            User.is_active == True,
        )
    )

    if name:
        query = query.filter(
            or_(
                Profile.first_name.ilike(f'%{name}%'),
                Profile.last_name.ilike(f'%{name}%'),
            )
        )

    if city:
        query = query.filter(Profile.city.ilike(f'%{city}%'))

    if gender:
        query = query.filter(Profile.gender == gender)

    # Age range filtering using date_of_birth
    if min_age or max_age:
        from datetime import date, timedelta
        today = date.today()
        if max_age:
            # Must be born at least max_age years ago
            min_dob = date(today.year - max_age - 1, today.month, today.day)
            query = query.filter(Profile.date_of_birth >= min_dob)
        if min_age:
            # Must be born at most min_age years ago
            max_dob = date(today.year - min_age, today.month, today.day)
            query = query.filter(Profile.date_of_birth <= max_dob)

    profiles = query.order_by(Profile.created_at.desc()).limit(50).all()

    # Filter by interests in Python (after query) if interest_ids provided
    if interest_ids:
        profiles = [
            p for p in profiles
            if any(i.interest_id in interest_ids for i in p.interests)
        ]

    return jsonify(profiles=[p.to_dict(include_user=True) for p in profiles]), 200

# ─── ADMIN / SEED ─────────────────────────────────────────────────────────────

@bp.route('/seed-interests', methods=['POST'])
def seed_interests():
    interests_data = [
        ('Hiking',       'outdoors'),    ('Photography', 'arts'),
        ('Gaming',       'tech'),        ('Cooking',     'food'),
        ('Traveling',    'travel'),      ('Music',       'arts'),
        ('Reading',      'education'),   ('Fitness',     'sports'),
        ('Dancing',      'arts'),        ('Movies',      'entertainment'),
        ('Coffee',       'food'),        ('Yoga',        'wellness'),
        ('Painting',     'arts'),        ('Cycling',     'sports'),
        ('Swimming',     'sports'),      ('Volunteering','social'),
        ('Technology',   'tech'),        ('Fashion',     'lifestyle'),
        ('Gardening',    'outdoors'),    ('Board Games', 'entertainment'),
    ]
    count = 0
    for name, cat in interests_data:
        if not Interest.query.filter_by(name=name).first():
            db.session.add(Interest(name=name, category=cat))
            count += 1
    db.session.commit()
    return jsonify(message=f'Seeded {count} interests.'), 200


# ─── ERROR HANDLERS ──────────────────────────────────────────────────────────

@bp.app_errorhandler(404)
def not_found(e):
    return jsonify(error='Not found.'), 404


@bp.app_errorhandler(405)
def method_not_allowed(e):
    return jsonify(error='Method not allowed.'), 405
