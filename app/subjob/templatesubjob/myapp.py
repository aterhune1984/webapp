#!/usr/bin/env python

# you will need to import your class that you script will run in
from .ts import TemplateSubJob
# import email so the output of your script will be sent to the end user once the job is finished
# I recommend this as if the webpage is closed the job will keep running and the user will still get
# their output.


# this function must exist in every added subjob
def programkickoff(sessiondata, sid, payload):
    # instanciate your class, passing in flask sessiondata,
    # sid(to know what websocket we are dealing with,
    # and payload from the website form.
    ts = TemplateSubJob(sessiondata, sid, payload)
    # call the startme function in your class to actually start whatever script you are running.
    ts.startme()
