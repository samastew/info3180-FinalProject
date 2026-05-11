"""
DriftDater — Flask REST API
All routes are prefixed with /api/v1
"""
import os
import uuid
from datetime import datetime, timezone, date
from flask import Blueprint, request, jsonify, current_app, send_from_directory
from flask_login import login_user, logout_user, login_required, current_user
from werkzeug.utils import secure_filename

from app import db
from app.models import (
    User, Profile, Interest, ProfilePhoto,
    Swipe, SwipeAction, Match, MatchStatusType, Conversation, Message,
    Favorite, Notification, UserBlock, UserReport,
    GenderType, LookingForType, RelationshipGoalType, EducationLevelType
)

api_bp = Blueprint('api', __name__, url_prefix='/api/v1')


# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────

def allowed_file(filename):
    exts = current_app.config.get('ALLOWED_EXTENSIONS', {'png','jpg','jpeg','gif','webp'})
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in exts


def save_photo(file):
    """Save uploaded photo, return relative URL."""
    ext = file.filename.rsplit('.', 1)[1].lower()
    fname = f"{uuid.uuid4().hex}.{ext}"
    upload_dir = current_app.config['UPLOAD_FOLDER']
    os.makedirs(upload_dir, exist_ok=True)
    file.save(os.path.join(upload_dir, fname))
    return f"/api/v1/uploads/{fname}"


def notify(user_id, ntype, message):
    n = Notification(user_id=user_id, type=ntype, message=message)
    db.session.add(n)


def get_or_create_match(uid_a, uid_b):
    """Return existing match or create a new one (+ conversation)."""
    u1, u2 = (uid_a, uid_b) if uid_a < uid_b else (uid_b, uid_a)
    m = Match.query.filter_by(user1_id=u1, user2_id=u2).first()
    if m:
        return m, False
    m = Match(user1_id=u1, user2_id=u2, status=MatchStatusType.active)
    db.session.add(m)
    db.session.flush()
    c = Conversation(match_id=m.match_id)
    db.session.add(c)
    return m, True


# ─────────────────────────────────────────────
# SERVE UPLOADED FILES
# ─────────────────────────────────────────────

@api_bp.route('/uploads/<path:filename>')
def uploaded_file(filename):
    return send_from_directory(current_app.config['UPLOAD_FOLDER'], filename)


# ─────────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────────

@api_bp.route('/auth/register', methods=['POST'])
def register():
    data = request.get_json(silent=True) or {}

    required = ['username', 'email', 'password', 'first_name', 'last_name',
                'date_of_birth', 'gender']
    for f in required:
        if not data.get(f):
            return jsonify({'error': f'Field "{f}" is required'}), 400

    if User.query.filter_by(email=data['email'].lower()).first():
        return jsonify({'error': 'Email already registered'}), 409
    if User.query.filter_by(username=data['username']).first():
        return jsonify({'error': 'Username already taken'}), 409

    try:
        dob = date.fromisoformat(data['date_of_birth'])
    except ValueError:
        return jsonify({'error': 'Invalid date_of_birth (YYYY-MM-DD)'}), 400

    age = (date.today() - dob).days // 365
    if age < 18:
        return jsonify({'error': 'Must be at least 18 years old'}), 400

    try:
        gender = GenderType(data['gender'])
    except ValueError:
        return jsonify({'error': 'Invalid gender value'}), 400

    user = User(
        username=data['username'],
        email=data['email'].lower(),
        email_verified=False,
        is_active=True,
        last_seen_at=datetime.now(timezone.utc)
    )
    user.set_password(data['password'])
    db.session.add(user)
    db.session.flush()

    profile = Profile(
        user_id=user.user_id,
        first_name=data['first_name'],
        last_name=data['last_name'],
        date_of_birth=dob,
        gender=gender,
        bio=data.get('bio', ''),
        city=data.get('city', ''),
        country=data.get('country', 'Jamaica'),
        latitude=data.get('latitude'),
        longitude=data.get('longitude'),
        looking_for=LookingForType(data['looking_for']) if data.get('looking_for') else LookingForType.any,
        min_age_pref=int(data.get('min_age_pref', 18)),
        max_age_pref=int(data.get('max_age_pref', 55)),
        max_distance_km=int(data.get('max_distance_km', 50)),
        occupation=data.get('occupation', ''),
        education_level=EducationLevelType(data['education_level']) if data.get('education_level') else None,
        relationship_goal=RelationshipGoalType(data['relationship_goal']) if data.get('relationship_goal') else None,
        is_visible=True,
    )
    db.session.add(profile)

    # Attach interests
    interest_ids = data.get('interest_ids', [])
    if interest_ids:
        interests = Interest.query.filter(Interest.interest_id.in_(interest_ids)).all()
        user.interests = interests

    db.session.commit()
    login_user(user, remember=True)
    user.last_seen_at = datetime.now(timezone.utc)
    db.session.commit()

    return jsonify({
        'message': 'Registration successful',
        'user': user.to_dict(include_private=True),
        'profile': profile.to_dict(),
    }), 201


@api_bp.route('/auth/login', methods=['POST'])
def login():
    data = request.get_json(silent=True) or {}

    identifier = data.get('email') or data.get('username')
    password   = data.get('password')

    if not identifier or not password:
        return jsonify({'error': 'Email/username and password required'}), 400

    user = (User.query.filter_by(email=identifier.lower()).first()
            or User.query.filter_by(username=identifier).first())

    if not user or not user.check_password(password):
        return jsonify({'error': 'Invalid credentials'}), 401

    if not user.is_active:
        return jsonify({'error': 'Account is deactivated'}), 403

    login_user(user, remember=True)
    user.last_seen_at = datetime.now(timezone.utc)
    db.session.commit()

    return jsonify({
        'message': 'Login successful',
        'user': user.to_dict(include_private=True),
        'profile': user.profile.to_dict() if user.profile else None,
    }), 200


@api_bp.route('/auth/logout', methods=['POST'])
@login_required
def logout():
    logout_user()
    return jsonify({'message': 'Logged out successfully'}), 200


@api_bp.route('/auth/me', methods=['GET'])
@login_required
def me():
    current_user.last_seen_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify({
        'user': current_user.to_dict(include_private=True),
        'profile': current_user.profile.to_dict() if current_user.profile else None,
        'interests': [i.to_dict() for i in current_user.interests],
        'photos': [p.to_dict() for p in current_user.photos],
    }), 200


# ─────────────────────────────────────────────
# INTERESTS (public)
# ─────────────────────────────────────────────

@api_bp.route('/interests', methods=['GET'])
def get_interests():
    interests = Interest.query.order_by(Interest.category, Interest.name).all()
    return jsonify([i.to_dict() for i in interests]), 200


# ─────────────────────────────────────────────
# USER PROFILE
# ─────────────────────────────────────────────

@api_bp.route('/users/<int:user_id>', methods=['GET'])
@login_required
def get_user(user_id):
    user = User.query.get_or_404(user_id)

    # Check if blocked
    block = UserBlock.query.filter_by(blocker_id=user_id, blocked_id=current_user.user_id).first()
    if block:
        return jsonify({'error': 'Not found'}), 404

    return jsonify({
        'user': user.to_dict(),
        'profile': user.profile.to_dict() if user.profile else None,
        'interests': [i.to_dict() for i in user.interests],
        'photos': [p.to_dict() for p in user.photos],
        'is_favorited': Favorite.query.filter_by(
            user_id=current_user.user_id, favorited_id=user_id).first() is not None,
        'swipe_action': _get_swipe_action(current_user.user_id, user_id),
    }), 200


def _get_swipe_action(swiper_id, swiped_id):
    sw = Swipe.query.filter_by(swiper_id=swiper_id, swiped_id=swiped_id).first()
    return sw.action.value if sw else None


@api_bp.route('/users/<int:user_id>', methods=['PUT'])
@login_required
def update_user(user_id):
    if current_user.user_id != user_id:
        return jsonify({'error': 'Forbidden'}), 403

    data = request.get_json(silent=True) or {}
    profile = current_user.profile

    if not profile:
        return jsonify({'error': 'Profile not found'}), 404

    # Updatable fields
    text_fields = ['first_name', 'last_name', 'bio', 'city', 'country', 'occupation']
    for f in text_fields:
        if f in data:
            setattr(profile, f, data[f])

    if 'date_of_birth' in data:
        try:
            profile.date_of_birth = date.fromisoformat(data['date_of_birth'])
        except ValueError:
            return jsonify({'error': 'Invalid date_of_birth'}), 400

    if 'gender' in data:
        try:
            profile.gender = GenderType(data['gender'])
        except ValueError:
            return jsonify({'error': 'Invalid gender'}), 400

    if 'looking_for' in data:
        try:
            profile.looking_for = LookingForType(data['looking_for'])
        except ValueError:
            return jsonify({'error': 'Invalid looking_for'}), 400

    if 'education_level' in data:
        try:
            profile.education_level = EducationLevelType(data['education_level'])
        except ValueError:
            return jsonify({'error': 'Invalid education_level'}), 400

    if 'relationship_goal' in data:
        try:
            profile.relationship_goal = RelationshipGoalType(data['relationship_goal'])
        except ValueError:
            return jsonify({'error': 'Invalid relationship_goal'}), 400

    if 'latitude'  in data: profile.latitude  = data['latitude']
    if 'longitude' in data: profile.longitude = data['longitude']
    if 'min_age_pref'    in data: profile.min_age_pref    = int(data['min_age_pref'])
    if 'max_age_pref'    in data: profile.max_age_pref    = int(data['max_age_pref'])
    if 'max_distance_km' in data: profile.max_distance_km = int(data['max_distance_km'])
    if 'is_visible'      in data: profile.is_visible      = bool(data['is_visible'])

    if 'username' in data:
        existing = User.query.filter_by(username=data['username']).first()
        if existing and existing.user_id != user_id:
            return jsonify({'error': 'Username taken'}), 409
        current_user.username = data['username']

    if 'interest_ids' in data:
        interests = Interest.query.filter(Interest.interest_id.in_(data['interest_ids'])).all()
        current_user.interests = interests

    profile.updated_at    = datetime.now(timezone.utc)
    current_user.updated_at = datetime.now(timezone.utc)
    db.session.commit()

    return jsonify({
        'message': 'Profile updated',
        'user': current_user.to_dict(include_private=True),
        'profile': profile.to_dict(),
        'interests': [i.to_dict() for i in current_user.interests],
    }), 200


# ─────────────────────────────────────────────
# PHOTO UPLOAD
# ─────────────────────────────────────────────

@api_bp.route('/users/<int:user_id>/photos', methods=['POST'])
@login_required
def upload_photo(user_id):
    if current_user.user_id != user_id:
        return jsonify({'error': 'Forbidden'}), 403

    if 'photo' not in request.files:
        return jsonify({'error': 'No photo file provided'}), 400

    file = request.files['photo']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    if not allowed_file(file.filename):
        return jsonify({'error': 'File type not allowed'}), 400

    url = save_photo(file)

    # First photo becomes primary
    make_primary = not current_user.photos
    if request.form.get('is_primary') == 'true':
        # Remove existing primary
        for p in current_user.photos:
            p.is_primary = False
        make_primary = True

    photo = ProfilePhoto(user_id=user_id, photo_url=url, is_primary=make_primary)
    db.session.add(photo)
    db.session.commit()

    return jsonify({'message': 'Photo uploaded', 'photo': photo.to_dict()}), 201


@api_bp.route('/users/<int:user_id>/photos', methods=['GET'])
@login_required
def get_photos(user_id):
    user = User.query.get_or_404(user_id)
    return jsonify([p.to_dict() for p in user.photos]), 200


@api_bp.route('/users/<int:user_id>/photos/<int:photo_id>', methods=['DELETE'])
@login_required
def delete_photo(user_id, photo_id):
    if current_user.user_id != user_id:
        return jsonify({'error': 'Forbidden'}), 403

    photo = ProfilePhoto.query.filter_by(photo_id=photo_id, user_id=user_id).first_or_404()
    was_primary = photo.is_primary
    db.session.delete(photo)
    db.session.flush()

    # Reassign primary
    if was_primary and current_user.photos:
        current_user.photos[0].is_primary = True

    db.session.commit()
    return jsonify({'message': 'Photo deleted'}), 200


# ─────────────────────────────────────────────
# DISCOVER / BROWSE
# ─────────────────────────────────────────────

@api_bp.route('/discover', methods=['GET'])
@login_required
def discover():
    """
    Returns profiles the current user hasn't swiped yet.
    Filtered by looking_for, age range, distance, interests.
    Scored by shared interests for ranking.
    """
    me_profile = current_user.profile
    if not me_profile:
        return jsonify({'error': 'Complete your profile first'}), 400

    page     = int(request.args.get('page',  1))
    per_page = int(request.args.get('limit', 20))

    # Filters from query params (override profile defaults)
    filter_gender     = request.args.get('gender')
    filter_min_age    = int(request.args.get('min_age',    me_profile.min_age_pref))
    filter_max_age    = int(request.args.get('max_age',    me_profile.max_age_pref))
    filter_max_dist   = int(request.args.get('max_distance_km', me_profile.max_distance_km))
    filter_goal       = request.args.get('relationship_goal')
    filter_interests  = request.args.getlist('interest_ids', type=int)

    # IDs already swiped
    swiped_ids = db.session.query(Swipe.swiped_id).filter_by(swiper_id=current_user.user_id).scalar_subquery()

    # IDs that blocked me
    blocked_me = db.session.query(UserBlock.blocker_id).filter_by(blocked_id=current_user.user_id).scalar_subquery()
    # IDs I blocked
    i_blocked  = db.session.query(UserBlock.blocked_id).filter_by(blocker_id=current_user.user_id).scalar_subquery()

    # Age range → date_of_birth range
    from datetime import timedelta
    today = date.today()
    dob_min = today - timedelta(days=filter_max_age * 365 + 365)
    dob_max = today - timedelta(days=filter_min_age * 365)

    query = (
        Profile.query
        .join(User, Profile.user_id == User.user_id)
        .filter(
            Profile.user_id != current_user.user_id,
            Profile.is_visible == True,
            User.is_active == True,
            Profile.date_of_birth.between(dob_min, dob_max),
            ~Profile.user_id.in_(swiped_ids),
            ~Profile.user_id.in_(blocked_me),
            ~Profile.user_id.in_(i_blocked),
        )
    )

    # Gender filter
    if filter_gender:
        try:
            query = query.filter(Profile.gender == GenderType(filter_gender))
        except ValueError:
            pass
    elif me_profile.looking_for and me_profile.looking_for != LookingForType.any:
        query = query.filter(Profile.gender == GenderType(me_profile.looking_for.value))

    # Relationship goal filter
    if filter_goal:
        try:
            query = query.filter(Profile.relationship_goal == RelationshipGoalType(filter_goal))
        except ValueError:
            pass

    profiles_all = query.all()

    # Distance filter & scoring
    results = []
    my_lat  = float(me_profile.latitude)  if me_profile.latitude  else None
    my_lon  = float(me_profile.longitude) if me_profile.longitude else None

    my_interest_ids = {i.interest_id for i in current_user.interests}

    for p in profiles_all:
        # Distance check
        dist = None
        if my_lat and my_lon and p.latitude and p.longitude:
            dist = p.distance_to(my_lat, my_lon)
            if dist > filter_max_dist:
                continue

        user_interest_ids = {i.interest_id for i in p.user.interests}
        shared = my_interest_ids & user_interest_ids

        # Interest filter
        if filter_interests and not (set(filter_interests) & user_interest_ids):
            continue

        score = len(shared) * 10
        if dist is not None:
            score += max(0, (filter_max_dist - dist))

        results.append((score, dist, p))

    # Sort by score descending
    results.sort(key=lambda x: -x[0])

    # Paginate
    total   = len(results)
    start   = (page - 1) * per_page
    end     = start + per_page
    page_results = results[start:end]

    output = []
    for score, dist, p in page_results:
        d = p.to_dict()
        d['user']            = p.user.to_dict()
        d['interests']       = [i.to_dict() for i in p.user.interests]
        d['photos']          = [ph.to_dict() for ph in p.user.photos]
        d['distance_km']     = round(dist, 1) if dist is not None else None
        d['shared_interests'] = len(my_interest_ids & {i.interest_id for i in p.user.interests})
        d['match_score']     = score
        output.append(d)

    return jsonify({
        'profiles': output,
        'total':    total,
        'page':     page,
        'pages':    (total + per_page - 1) // per_page,
    }), 200


# ─────────────────────────────────────────────
# SWIPE
# ─────────────────────────────────────────────

@api_bp.route('/swipe', methods=['POST'])
@login_required
def swipe():
    data = request.get_json(silent=True) or {}

    target_id = data.get('user_id')
    action    = data.get('action')  # like | dislike | pass

    if not target_id or not action:
        return jsonify({'error': 'user_id and action required'}), 400

    if target_id == current_user.user_id:
        return jsonify({'error': 'Cannot swipe yourself'}), 400

    try:
        swipe_action = SwipeAction(action)
    except ValueError:
        return jsonify({'error': 'action must be like, dislike, or pass'}), 400

    target = User.query.get(target_id)
    if not target:
        return jsonify({'error': 'User not found'}), 404

    # Upsert swipe
    existing = Swipe.query.filter_by(swiper_id=current_user.user_id, swiped_id=target_id).first()
    if existing:
        existing.action     = swipe_action
        existing.updated_at = datetime.now(timezone.utc)
    else:
        existing = Swipe(swiper_id=current_user.user_id, swiped_id=target_id, action=swipe_action)
        db.session.add(existing)

    db.session.flush()

    matched = False
    match_data = None

    if swipe_action == SwipeAction.like:
        # Check mutual like
        reverse = Swipe.query.filter_by(
            swiper_id=target_id, swiped_id=current_user.user_id, action=SwipeAction.like
        ).first()

        if reverse:
            match, created = get_or_create_match(current_user.user_id, target_id)
            matched = True

            if created:
                notify(current_user.user_id, 'match',
                       f"You matched with {target.profile.first_name if target.profile else target.username}!")
                notify(target_id, 'match',
                       f"You matched with {current_user.profile.first_name if current_user.profile else current_user.username}!")

            match_data = match.to_dict(current_user.user_id)
        else:
            notify(target_id, 'like',
                   f"{current_user.profile.first_name if current_user.profile else current_user.username} liked your profile!")

    db.session.commit()

    return jsonify({
        'message': 'Swipe recorded',
        'action':  action,
        'matched': matched,
        'match':   match_data,
    }), 200


# ─────────────────────────────────────────────
# MATCHES
# ─────────────────────────────────────────────

@api_bp.route('/matches', methods=['GET'])
@login_required
def get_matches():
    uid = current_user.user_id
    matches = (
        Match.query
        .filter(
            ((Match.user1_id == uid) | (Match.user2_id == uid)),
            Match.status == MatchStatusType.active
        )
        .order_by(Match.matched_at.desc())
        .all()
    )
    return jsonify([m.to_dict(uid) for m in matches]), 200


@api_bp.route('/matches/<int:match_id>', methods=['DELETE'])
@login_required
def unmatch(match_id):
    uid = current_user.user_id
    match = Match.query.filter(
        Match.match_id == match_id,
        (Match.user1_id == uid) | (Match.user2_id == uid)
    ).first_or_404()

    match.status = MatchStatusType.unmatched
    db.session.commit()
    return jsonify({'message': 'Unmatched'}), 200


# ─────────────────────────────────────────────
# CONVERSATIONS & MESSAGES
# ─────────────────────────────────────────────

@api_bp.route('/conversations', methods=['GET'])
@login_required
def get_conversations():
    uid = current_user.user_id
    matches = (
        Match.query
        .filter(
            ((Match.user1_id == uid) | (Match.user2_id == uid)),
            Match.status == MatchStatusType.active
        )
        .all()
    )

    result = []
    for m in matches:
        if not m.conversation:
            continue
        last = m.conversation.last_message()
        other = m.other_user(uid)
        unread = Message.query.filter_by(
            conversation_id=m.conversation.conversation_id,
            is_read=False
        ).filter(Message.sender_id != uid).count()

        result.append({
            'conversation_id': m.conversation.conversation_id,
            'match_id':        m.match_id,
            'other_user':      other.to_dict() if other else None,
            'other_profile':   other.profile.to_dict() if other and other.profile else None,
            'last_message':    last.to_dict() if last else None,
            'unread_count':    unread,
            'matched_at':      m.matched_at.isoformat() if m.matched_at else None,
        })

    # Sort by last message date
    result.sort(
        key=lambda x: x['last_message']['sent_at'] if x['last_message'] else x['matched_at'] or '',
        reverse=True
    )
    return jsonify(result), 200


@api_bp.route('/conversations/<int:convo_id>/messages', methods=['GET'])
@login_required
def get_messages(convo_id):
    uid = current_user.user_id
    convo = Conversation.query.get_or_404(convo_id)

    # Auth: must be part of the match
    m = convo.match
    if uid not in (m.user1_id, m.user2_id):
        return jsonify({'error': 'Forbidden'}), 403

    # Mark messages as read
    Message.query.filter_by(
        conversation_id=convo_id, is_read=False
    ).filter(Message.sender_id != uid).update({'is_read': True})
    db.session.commit()

    page     = int(request.args.get('page',  1))
    per_page = int(request.args.get('limit', 50))

    paginated = (
        Message.query
        .filter_by(conversation_id=convo_id)
        .order_by(Message.sent_at.desc())
        .paginate(page=page, per_page=per_page, error_out=False)
    )

    msgs = list(reversed(paginated.items))
    return jsonify({
        'messages': [msg.to_dict() for msg in msgs],
        'total': paginated.total,
        'page':  page,
        'pages': paginated.pages,
    }), 200


@api_bp.route('/conversations/<int:convo_id>/messages', methods=['POST'])
@login_required
def send_message(convo_id):
    uid = current_user.user_id
    convo = Conversation.query.get_or_404(convo_id)
    m     = convo.match

    if uid not in (m.user1_id, m.user2_id):
        return jsonify({'error': 'Forbidden'}), 403

    if m.status != MatchStatusType.active:
        return jsonify({'error': 'Match is no longer active'}), 400

    data = request.get_json(silent=True) or {}
    body = data.get('body', '').strip()

    if not body:
        return jsonify({'error': 'Message body cannot be empty'}), 400

    msg = Message(conversation_id=convo_id, sender_id=uid, body=body)
    db.session.add(msg)

    # Notify the other user
    other_id = m.user2_id if uid == m.user1_id else m.user1_id
    me_name  = current_user.profile.first_name if current_user.profile else current_user.username
    notify(other_id, 'message', f"{me_name} sent you a message.")

    db.session.commit()
    return jsonify({'message': 'Sent', 'data': msg.to_dict()}), 201


# ─────────────────────────────────────────────
# SEARCH
# ─────────────────────────────────────────────

@api_bp.route('/search', methods=['GET'])
@login_required
def search():
    uid = current_user.user_id

    q             = request.args.get('q', '').strip()
    city          = request.args.get('city', '')
    min_age       = request.args.get('min_age',  type=int)
    max_age       = request.args.get('max_age',  type=int)
    gender        = request.args.get('gender', '')
    goal          = request.args.get('relationship_goal', '')
    interest_ids  = request.args.getlist('interest_ids', type=int)
    sort          = request.args.get('sort', 'newest')  # newest | most_similar
    page          = int(request.args.get('page', 1))
    per_page      = int(request.args.get('limit', 20))

    blocked_me = db.session.query(UserBlock.blocker_id).filter_by(blocked_id=uid).scalar_subquery()
    i_blocked  = db.session.query(UserBlock.blocked_id).filter_by(blocker_id=uid).scalar_subquery()

    query = (
        Profile.query
        .join(User, Profile.user_id == User.user_id)
        .filter(
            Profile.user_id != uid,
            Profile.is_visible == True,
            User.is_active == True,
            ~Profile.user_id.in_(blocked_me),
            ~Profile.user_id.in_(i_blocked),
        )
    )

    if q:
        like = f'%{q}%'
        query = query.filter(
            (Profile.first_name.ilike(like)) |
            (Profile.last_name.ilike(like)) |
            (Profile.bio.ilike(like)) |
            (Profile.occupation.ilike(like)) |
            (User.username.ilike(like))
        )

    if city:
        query = query.filter(Profile.city.ilike(f'%{city}%'))

    if min_age:
        from datetime import timedelta
        dob_max = date.today() - timedelta(days=min_age * 365)
        query = query.filter(Profile.date_of_birth <= dob_max)

    if max_age:
        from datetime import timedelta
        dob_min = date.today() - timedelta(days=(max_age + 1) * 365)
        query = query.filter(Profile.date_of_birth >= dob_min)

    if gender:
        try:
            query = query.filter(Profile.gender == GenderType(gender))
        except ValueError:
            pass

    if goal:
        try:
            query = query.filter(Profile.relationship_goal == RelationshipGoalType(goal))
        except ValueError:
            pass

    profiles_all = query.all()

    my_interest_ids = {i.interest_id for i in current_user.interests}

    results = []
    for p in profiles_all:
        user_interest_ids = {i.interest_id for i in p.user.interests}

        # Interest filter
        if interest_ids and not (set(interest_ids) & user_interest_ids):
            continue

        shared = len(my_interest_ids & user_interest_ids)
        results.append((shared, p))

    if sort == 'most_similar':
        results.sort(key=lambda x: -x[0])
    else:  # newest
        def _created(x):
            ts = x[1].user.created_at
            if ts is None:
                return datetime.min.replace(tzinfo=timezone.utc)
            if ts.tzinfo is None:
                return ts.replace(tzinfo=timezone.utc)
            return ts
        results.sort(key=_created, reverse=True)

    total  = len(results)
    start  = (page - 1) * per_page
    page_r = results[start:start + per_page]

    output = []
    for shared, p in page_r:
        d = p.to_dict()
        d['user']             = p.user.to_dict()
        d['interests']        = [i.to_dict() for i in p.user.interests]
        d['photos']           = [ph.to_dict() for ph in p.user.photos]
        d['shared_interests'] = shared
        output.append(d)

    return jsonify({
        'profiles': output,
        'total':    total,
        'page':     page,
        'pages':    (total + per_page - 1) // per_page,
    }), 200


# ─────────────────────────────────────────────
# FAVORITES
# ─────────────────────────────────────────────

@api_bp.route('/favorites', methods=['GET'])
@login_required
def get_favorites():
    uid = current_user.user_id
    favs = (
        db.session.query(Favorite, User, Profile)
        .join(User,    User.user_id    == Favorite.favorited_id)
        .outerjoin(Profile, Profile.user_id == Favorite.favorited_id)
        .filter(Favorite.user_id == uid)
        .order_by(Favorite.created_at.desc())
        .all()
    )
    result = []
    for fav, user, profile in favs:
        d = {
            'favorited_at': fav.created_at.isoformat() if fav.created_at else None,
            'user':         user.to_dict(),
            'profile':      profile.to_dict() if profile else None,
        }
        result.append(d)
    return jsonify(result), 200


@api_bp.route('/favorites/<int:target_id>', methods=['POST'])
@login_required
def add_favorite(target_id):
    uid = current_user.user_id
    if uid == target_id:
        return jsonify({'error': 'Cannot favorite yourself'}), 400

    existing = Favorite.query.filter_by(user_id=uid, favorited_id=target_id).first()
    if existing:
        return jsonify({'message': 'Already favorited'}), 200

    fav = Favorite(user_id=uid, favorited_id=target_id)
    db.session.add(fav)
    db.session.commit()
    return jsonify({'message': 'Added to favorites'}), 201


@api_bp.route('/favorites/<int:target_id>', methods=['DELETE'])
@login_required
def remove_favorite(target_id):
    uid = current_user.user_id
    fav = Favorite.query.filter_by(user_id=uid, favorited_id=target_id).first_or_404()
    db.session.delete(fav)
    db.session.commit()
    return jsonify({'message': 'Removed from favorites'}), 200


# ─────────────────────────────────────────────
# NOTIFICATIONS
# ─────────────────────────────────────────────

@api_bp.route('/notifications', methods=['GET'])
@login_required
def get_notifications():
    uid  = current_user.user_id
    page = int(request.args.get('page', 1))
    notifs = (
        Notification.query
        .filter_by(user_id=uid)
        .order_by(Notification.created_at.desc())
        .paginate(page=page, per_page=30, error_out=False)
    )
    unread = Notification.query.filter_by(user_id=uid, is_read=False).count()
    return jsonify({
        'notifications': [n.to_dict() for n in notifs.items],
        'unread_count': unread,
        'total': notifs.total,
    }), 200


@api_bp.route('/notifications/<int:notif_id>/read', methods=['PUT'])
@login_required
def mark_notification_read(notif_id):
    n = Notification.query.filter_by(
        notification_id=notif_id, user_id=current_user.user_id
    ).first_or_404()
    n.is_read = True
    db.session.commit()
    return jsonify({'message': 'Marked as read'}), 200


@api_bp.route('/notifications/read-all', methods=['PUT'])
@login_required
def mark_all_notifications_read():
    Notification.query.filter_by(user_id=current_user.user_id, is_read=False).update({'is_read': True})
    db.session.commit()
    return jsonify({'message': 'All marked as read'}), 200


# ─────────────────────────────────────────────
# BLOCK & REPORT
# ─────────────────────────────────────────────

@api_bp.route('/users/<int:target_id>/block', methods=['POST'])
@login_required
def block_user(target_id):
    uid = current_user.user_id
    if uid == target_id:
        return jsonify({'error': 'Cannot block yourself'}), 400

    existing = UserBlock.query.filter_by(blocker_id=uid, blocked_id=target_id).first()
    if existing:
        return jsonify({'message': 'Already blocked'}), 200

    block = UserBlock(blocker_id=uid, blocked_id=target_id)
    db.session.add(block)

    # Archive any existing match
    u1, u2 = (uid, target_id) if uid < target_id else (target_id, uid)
    match = Match.query.filter_by(user1_id=u1, user2_id=u2).first()
    if match:
        match.status = MatchStatusType.blocked

    db.session.commit()
    return jsonify({'message': 'User blocked'}), 201


@api_bp.route('/users/<int:target_id>/report', methods=['POST'])
@login_required
def report_user(target_id):
    uid = current_user.user_id
    if uid == target_id:
        return jsonify({'error': 'Cannot report yourself'}), 400

    data   = request.get_json(silent=True) or {}
    reason = data.get('reason', '').strip()

    if not reason:
        return jsonify({'error': 'Reason is required'}), 400

    report = UserReport(reporter_id=uid, reported_id=target_id, reason=reason)
    db.session.add(report)
    db.session.commit()
    return jsonify({'message': 'Report submitted'}), 201


# ─────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────

@api_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'app': 'DriftDater'}), 200
