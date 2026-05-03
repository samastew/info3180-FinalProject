"""
Flask Documentation:     https://flask.palletsprojects.com/
Jinja2 Documentation:    https://jinja.palletsprojects.com/
Werkzeug Documentation:  https://werkzeug.palletsprojects.com/
This file creates your application.
"""

from app import app, db
from app.models import User, Interest
from flask import request, jsonify, session
import os
import math


@app.route('/')
def index():
    return jsonify(message="This is the beginning of our API")


@app.route('/api/search', methods=['GET'])
def search_users():
    #if 'user_id' not in session:
    #    return jsonify(error="Unauthorized"), 401
    min_age       = request.args.get('min_age', 18, type=int)
    max_age       = request.args.get('max_age', 99, type=int)
    city          = request.args.get('city', '', type=str).strip()
    interests_raw = request.args.get('interests', '', type=str).strip()
    looking_for   = request.args.get('looking_for', '', type=str).strip()
    max_dist      = request.args.get('max_distance_km', 9999, type=int)
    sort          = request.args.get('sort', 'newest', type=str)
    page          = request.args.get('page', 1, type=int)
    per_page      = request.args.get('per_page', 20, type=int)
    viewer_lat    = request.args.get('lat', None, type=float)
    viewer_lng    = request.args.get('lng', None, type=float)

    query = User.query.filter(User.is_public == True)
    query = query.filter(User.age >= min_age, User.age <= max_age)

    if city:
        query = query.filter(User.city.ilike(f'%{city}%'))

    if looking_for:
        query = query.filter(User.looking_for == looking_for)

    if interests_raw:
        requested = [i.strip() for i in interests_raw.split(',') if i.strip()]
        for interest_name in requested:
            query = query.filter(User.interests.any(Interest.name == interest_name))

    if sort == 'newest':
        query = query.order_by(User.created_at.desc())

    all_candidates = query.all()

    def haversine_km(lat1, lng1, lat2, lng2):
        R = 6371
        dlat = math.radians(lat2 - lat1)
        dlng = math.radians(lng2 - lng1)
        a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng/2)**2
        return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    results = []
    for user in all_candidates:
        dist = None
        if viewer_lat is not None and viewer_lng is not None and user.latitude and user.longitude:
            dist = haversine_km(viewer_lat, viewer_lng, user.latitude, user.longitude)
            if dist > max_dist:
                continue

        u_dict = user.to_dict()
        u_dict['match_score'] = 50
        u_dict['shared_interests'] = []
        if dist is not None:
            u_dict['distance_km'] = round(dist, 1)

        results.append(u_dict)

    total = len(results)
    start = (page - 1) * per_page
    paged = results[start:start + per_page]

    return jsonify({
        'users': paged,
        'total': total,
        'page': page,
        'pages': math.ceil(total / per_page) if per_page else 1,
    }), 200


def form_errors(form):
    error_messages = []
    for field, errors in form.errors.items():
        for error in errors:
            message = u"Error in the %s field - %s" % (
                getattr(form, field).label.text, error)
            error_messages.append(message)
    return error_messages


@app.after_request
def add_header(response):
    response.headers['X-UA-Compatible'] = 'IE=Edge,chrome=1'
    response.headers['Cache-Control'] = 'public, max-age=0'
    return response


@app.errorhandler(404)
def page_not_found(error):
    return jsonify(error="Not found"), 404