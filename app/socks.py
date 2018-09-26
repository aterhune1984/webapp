from app import socketio, app
from flask import request, session
from .threads import timethread, timethread_lock, time_thread
from flask_socketio import emit
from .helper import emitter, unstringify
from .ctasks import subjobstart

@socketio.on('connect', namespace='/socket')
def test_connect():
    app.logger.debug('client {0} connected'.format(request.sid))
    global timethread
    with timethread_lock:
        if timethread is None:
            timethread = socketio.start_background_task(time_thread)


@socketio.on('my_ping', namespace='/socket')
def ping_pong():
    emit('my_pong')


@socketio.on('job_submit', namespace='/socket')
def job_submit(message):
    # print('recieved job_submit message from client')
    # kick off subjob in celery task
    data = unstringify(message)
    # print('data = {0}'.format(data))
    sessiondata = dict(session)
    # print('sessiondata = {}'.format(sessiondata))
    subjobstart.delay(sessiondata, request.sid, data)

@socketio.on('my_event', namespace='/socket')
def test_message(message):
    emitter('received data {0}'.format(message))


timethread = timethread
