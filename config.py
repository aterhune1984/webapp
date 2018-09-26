import os

SOCKETIO_PING_TIMEOUT = 86400
SOCKETIO_PING_INTERVAL = 60
SESSION_LENGTH = 30
SECRET_KEY = 'secret'

if os.environ.get('REDIS_HOST') == None:
    REDIS_HOST = '127.0.0.1'
else:
    REDIS_HOST = os.environ.get('REDIS_HOST')


REDIS_PASSWORD = 'foobared' if os.environ.get('REDIS_PASSWORD') == None else os.environ.get('REDIS_PASSWORD')
SOCKETIO_REDIS_URL = 'redis://:{0}@{1}:6379/0'.format(REDIS_PASSWORD, REDIS_HOST)
CELERY_BROKER_URL = 'redis://:{0}@{1}:6379/0'.format(REDIS_PASSWORD, REDIS_HOST)
CELERY_RESULT_BACKEND = 'redis://:{0}@{1}:6379/0'.format(REDIS_PASSWORD, REDIS_HOST)
CELERY_ACCEPT_CONTENT = ['pickle', 'json']
CELERY_ANNOTATIONS = {'tasks.type_api': {'rate_limit': '40/s'},
                      'tasks.webrequest': {'rate_limit': '40/s'},
                      'tasks.interface_api': {'rate_limit': '40/s'},
                      'tasks.interface_name': {'rate_limit': '40/s'},
                      'tasks.xmlrpc': {'rate_limit': '2/s'},
                      'tasks.api_call': {'rate_limit': '2/s'},
                      'tasks.auth_api_call': {'rate_limit': '2/s'}}

# ========================================================================
# enable this to bypass celery and enable the use of breakpoints in your code, This only works on a mac.
debug = False
# ========================================================================

# only enable debugging if you are on a mac.
if os.path.exists('/Users'):
    if debug:
        CELERY_ALWAYS_EAGER = True
        CELERY_EAGER_PROPAGATES_EXCEPTIONS = True
