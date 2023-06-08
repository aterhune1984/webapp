import importlib
import traceback


def subjobstart(sessiondata, sid, payload):
    # dynamically import the correct subjob and execute programkickoff function with sessiondata,sid,payload
    print('in subjobstart')
    try:
        job = importlib.import_module('app.subjob.{0}.myapp'.format(payload['task']))
        job.programkickoff(sessiondata, sid, payload)
    except:
        pass