
from datetime import timedelta
from os import environ

# To start testing :
# - 1 : with exist template > debug false , test true , comment build and update theme  .
# - 2 : without template > debug false , test true.
DEBUG = True if environ.get('DEBUG', False) == 'True' else False
TESTING = False if DEBUG else True
TEMPLATES_AUTO_RELOAD = True
# SEND_FILE_MAX_AGE_DEFAULT = 0
# BABEL_DEFAULT_LOCALE = 'fr'
CORS_HEADERS = 'Content-Type'
# they will never get the plain text cookies and so these can never be stolen with XSS.
SESSION_TYPE = 'filesystem'
SESSION_FILE_DIR = 'Backend/session'
PERMANENT_SESSION_LIFETIME = timedelta(hours=5)
SESSION_FILE_THRESHOLD = 100
# 'SESSION_COOKIE_SECURE=True' on development causes session creation problems 
# when accessing storefront using the IP address or accessing private addresses
SESSION_COOKIE_SECURE = False if DEBUG else True 
SESSION_COOKIE_HTTPONLY = False
SESSION_COOKIE_NAME = 'storefront'
SESSION_COOKIE_SAMESITE = 'Lax'
# for the debug toolbar
DEBUG_TB_INTERCEPT_REDIRECTS = False
#site map configuration
SITEMAP_INCLUDE_RULES_WITHOUT_PARAMS=True
