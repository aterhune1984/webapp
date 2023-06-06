from __future__ import print_function

from flask_socketio import emit
from redis import Redis
from config import *
from app import socketio
from functools import wraps
from json import loads, dumps
from time import sleep
import inspect



def test_emit():
    emit('my_response', {'data': '<br>'}, namespace='/socket')

def emitter(message):
    #print('trying to send message to client')
    emit('my_response', {'data': '{0}<br>'.format(message)}, namespace='/socket')


def connect_to_redis():
    return Redis(host=REDIS_HOST,
                 port=6379,
                 db=0,
                 password=REDIS_PASSWORD)

def unstringify(message):
    d = {}
    for x in loads(message['data']):
        d[x['name']] = x['value']
    return d

def print(*args, **kwargs):
    # override print function in so someone can just copy paste a script and
    # any print function will instead of printing, actually call ws_send function

    # look into frame that called me so I can get the variables of 'payload' and 'sid' as these are required to be able
    # to use the ws_send function
    curframe = inspect.currentframe()  # current frame
    calframe = inspect.getouterframes(curframe, 2)  # calling frame
    try:
        payload = calframe[1].frame.f_locals['self'].payload   # get calling frames local variable 'payload'
        sid = calframe[1].frame.f_locals['self'].sid           # get calling frames local variable 'sid'
    finally:
        del curframe
        del calframe
    return ws_send(sid, payload, args[0])


def ws_send(sid, data, message):
    socketio.emit('my_response', {'data': '{0}<br>'.format(message)}, namespace='/socket', room=sid)
    # if data is a dictionary and key contains 'account' and value is not 'ignoreme' then skip



def nodup(f):
    @wraps(f)
    def wrapped(*args, **kwargs):
        sid = args[1]
        message = dumps(args[2])
        # ws_send(sid, {'{0}.account'.format(args[2]['task']): 'ignoreme'}, message)
        if r_server.sismember('celery_tasks', sid+message):
            ws_send(sid, {'{0}.account'.format(args[2]['task']): 'ignoreme'}, '{0} job is still running!'.format(loads(message)['task']))
        else:
            ws_send(sid, {'{0}.account'.format(args[2]['task']): 'ignoreme'}, '{0} job is starting...'.format(loads(message)['task']))
            r_server.sadd('celery_tasks', sid+message)
            r = f(*args, **kwargs)
            r_server.srem('celery_tasks', sid+message)
            ws_send(sid, {'{0}.account'.format(args[2]['task']): 'ignoreme'}, '{0} job has finished!'.format(loads(message)['task']))
            return r
    return wrapped



def wait_to_finish(*args):
    # if self.data['pull']:
    finished = 0
    while finished != 1:

        summary = []
        if isinstance(args[0], dict):
            for name, job in args[0].items():
                try:
                    summary.append(job.status)
                    if 'RETRY' in job.status:
                        sleep(1)
                        pass
                        #print('retrying {0}'.format(job))
                    if 'FAIL' in job.status:
                        pass
                        #print('fail {0}'.format(job))
                except:
                    summary.append(job['speed'].status)
                    summary.append(job['name'].status)
                    if 'RETRY' in job['speed'].status:
                        pass
                        # print 'retrying {0}'.format(job)
                    if 'RETRY' in job['name'].status:
                        pass
                        # print 'retrying {0}'.format(job)

            if 'PENDING' in summary or 'RETRY' in summary:
                sleep(.1)
            else:
                finished = 1
        else:
            sleep(.1)
            if 'PENDING' in args[0].status or 'RETRY' in args[0].status:
                pass
            else:
                finished = 1
    return finished


r_server = connect_to_redis()
