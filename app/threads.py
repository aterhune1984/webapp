from threading import Lock
import datetime
from app import socketio
from .helper import connect_to_redis

timethread = None
timethread_lock = Lock()
threads = {}
r_server = connect_to_redis()


def time_thread():
    while True:
        time = datetime.datetime.now()
        socketio.sleep(5)
        socketio.emit('my_time', {'data': str(time)}, namespace='/socket')
