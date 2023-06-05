#!/usr/bin/env python
# to start celery:
#   celery -A app.celery  worker -Ofair -l info

from flask import Flask
from flask_socketio import SocketIO
from celery import Celery
from redis import Redis
from config import *
import os
if not os.path.exists('/Users'):
    import eventlet
    eventlet.monkey_patch()
    # Set this variable to "threading", "eventlet" or "gevent" to test the
    # different async modes, or leave it set to None for the application to choose
    # the best option based on installed packages.
    async_mode = 'eventlet'
else:
    async_mode = 'threading'
from prometheus_flask_exporter import PrometheusMetrics


# cleanup tasks if we restarted uncleanly
r_server = Redis(host=REDIS_HOST,
                 port=6379,
                 db=0,
                 password=REDIS_PASSWORD)
r_server.delete('celery_tasks')

app = Flask(__name__)
metrics = PrometheusMetrics(app)
app.config.from_object('config')
socketio = SocketIO(app,
                    async_mode=async_mode,
                    message_queue=app.config['SOCKETIO_REDIS_URL'],
                    ping_timeout=SOCKETIO_PING_TIMEOUT,
                    ping_interval=SOCKETIO_PING_INTERVAL)
celery = Celery(app.name, broker=app.config['CELERY_BROKER_URL'])
celery.conf.update(app.config)

from app import views, socks, helper
