"""
Flask-WTF form classes for DriftDater.
These are used server-side for any HTML form endpoints.
The Vue frontend sends JSON directly to the API, so most validation
is done in views.py. These forms are kept for completeness / future use.
"""
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, EmailField, SelectField, TextAreaField, DateField
from wtforms.validators import DataRequired, Email, Length, EqualTo, Optional, NumberRange


class RegistrationForm(FlaskForm):
    username       = StringField('Username',    validators=[DataRequired(), Length(3, 50)])
    email          = EmailField('Email',        validators=[DataRequired(), Email()])
    password       = PasswordField('Password',  validators=[DataRequired(), Length(8)])
    confirm        = PasswordField('Confirm',   validators=[DataRequired(), EqualTo('password')])
    first_name     = StringField('First Name',  validators=[DataRequired(), Length(1, 50)])
    last_name      = StringField('Last Name',   validators=[DataRequired(), Length(1, 50)])
    date_of_birth  = DateField('Date of Birth', validators=[DataRequired()])
    gender         = SelectField('Gender',
                       choices=[('male','Male'),('female','Female'),
                                ('non_binary','Non-Binary'),('other','Other')],
                       validators=[DataRequired()])
    looking_for    = SelectField('Looking For',
                       choices=[('any','Anyone'),('male','Men'),
                                ('female','Women'),('non_binary','Non-Binary')])
    bio            = TextAreaField('Bio', validators=[Optional(), Length(max=1000)])
    city           = StringField('City',        validators=[Optional(), Length(max=100)])
    country        = StringField('Country',     validators=[Optional(), Length(max=100)])
    occupation     = StringField('Occupation',  validators=[Optional(), Length(max=100)])
    relationship_goal = SelectField('Relationship Goal',
                          choices=[('','Any'),('casual','Casual'),('serious','Serious'),
                                   ('friendship','Friendship'),('marriage','Marriage')],
                          validators=[Optional()])
    education_level = SelectField('Education',
                        choices=[('','Select'),('high_school','High School'),
                                 ('associate','Associate'),('bachelors',"Bachelor's"),
                                 ('masters',"Master's"),('phd','PhD'),('other','Other')],
                        validators=[Optional()])


class LoginForm(FlaskForm):
    email    = StringField('Email or Username', validators=[DataRequired()])
    password = PasswordField('Password',        validators=[DataRequired()])


class ProfileEditForm(FlaskForm):
    first_name        = StringField('First Name',  validators=[DataRequired(), Length(1, 50)])
    last_name         = StringField('Last Name',   validators=[DataRequired(), Length(1, 50)])
    bio               = TextAreaField('Bio',        validators=[Optional(), Length(max=1000)])
    city              = StringField('City',         validators=[Optional(), Length(max=100)])
    country           = StringField('Country',      validators=[Optional(), Length(max=100)])
    occupation        = StringField('Occupation',   validators=[Optional(), Length(max=100)])
    min_age_pref      = StringField('Min Age',      validators=[Optional()])
    max_age_pref      = StringField('Max Age',      validators=[Optional()])
    max_distance_km   = StringField('Max Distance', validators=[Optional()])


class ReportForm(FlaskForm):
    reason = TextAreaField('Reason', validators=[DataRequired(), Length(5, 500)])
