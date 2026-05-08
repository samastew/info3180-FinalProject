from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from .config import Config

db   = SQLAlchemy()
jwt  = JWTManager()
cors = CORS()


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    jwt.init_app(app)
    # Allow requests from the Vue dev server and any localhost port
    cors.init_app(app, resources={r'/api/*': {'origins': ['http://localhost:5173', 'http://127.0.0.1:5173', 'http://localhost:3000', 'http://127.0.0.1:8080']}}, supports_credentials=True)

    with app.app_context():
        from . import models  # registers all ORM classes with SQLAlchemy
        db.create_all()       # creates any tables that don't exist yet

    from .views import bp
    app.register_blueprint(bp)

    # Root route — confirms server is running when visiting 127.0.0.1:8080
    @app.route('/')
    def root():
        from flask import jsonify
        return jsonify(
            status='ok',
            message='DriftDater API server is running. All routes are under /api/',
            health_check='/api/health',
            api_info='/api/'
        ), 200

    return app
