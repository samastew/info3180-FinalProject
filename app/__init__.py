from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_login import LoginManager
from flask_cors import CORS
from .config import DevelopmentConfig

db      = SQLAlchemy()
migrate = Migrate()
login_manager = LoginManager()


def create_app(config_class=DevelopmentConfig):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    migrate.init_app(app, db)
    login_manager.init_app(app)

    CORS(app,
         supports_credentials=True,
         origins=['http://localhost:5173', 'http://127.0.0.1:5173',
                  'http://localhost:3000',  'http://127.0.0.1:3000'])

    login_manager.login_view = None  # API — no redirect

    import os
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

    from app import views  # noqa: F401  register routes
    app.register_blueprint(views.api_bp)

    return app


@login_manager.user_loader
def load_user(user_id):
    from app.models import User
    return User.query.get(int(user_id))


@login_manager.unauthorized_handler
def unauthorized():
    from flask import jsonify
    return jsonify({'error': 'Authentication required'}), 401
