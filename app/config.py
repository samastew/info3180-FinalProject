import os
import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    DEBUG            = False
    SECRET_KEY       = os.environ.get('SECRET_KEY', 'driftdater-secret-key-change-in-production')
    JWT_SECRET_KEY   = os.environ.get('JWT_SECRET_KEY', 'driftdater-jwt-secret-change-in-production')
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL',
        'postgresql://postgres:password@localhost/driftdater'
    ).replace('postgres://', 'postgresql://')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    UPLOAD_FOLDER    = os.environ.get('UPLOAD_FOLDER', 'uploads')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16 MB
    JWT_ACCESS_TOKEN_EXPIRES = 86400  # 1 day in seconds
