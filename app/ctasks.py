
from app import celery
from app.subjob import subjobkickoff
from app.helper import nodup
import importlib
import os



# need to import all subjobs here so celery knows about any tasks that might have been used
# get a list of all subjobs and remove anything that we don't want (pycache and subjobkickoff)
subjobs = os.listdir('{0}/subjob'.format(os.path.dirname(os.path.realpath(__file__))))
try:
    subjobs.remove('__pycache__')
except ValueError:
    pass
subjobs.remove('subjobkickoff.py')
for sj in subjobs:
    importlib.import_module('app.subjob.{0}.myapp'.format(sj))


@celery.task()
# @nodup
def subjobstart(sessiondata, sid, payload):
    subjobkickoff.subjobstart(sessiondata, sid, payload)

