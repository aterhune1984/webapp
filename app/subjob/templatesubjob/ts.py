from app.helper import print
import time

# NOTE: if your code contains API calls, make sure to put some kind of rate limit in
# so you dont get blocked. if you want, celery is setup already with a rate limit.
# you can use:
# from app.ctasks import api_call
# api_call.delay(request, session)
# to kick off concurrent requests to core api and celery will handle the rate limiting
# you will need to make sure you wait for these jobs to finish before referencing the
# result.  Please see coregrapher > coreg.py and edgecheck > ec.py for examples.

class TemplateSubJob:
    def __init__(self, sessiondata, sid, payload):
        self.session = sessiondata
        self.sid = sid
        self.payload = payload



    def startme(self):
        # i am running some code now...
        print('hello world!')
        print('starting some intensive process')
        with open('/hello/world.txt', 'w') as f:
            f.write('test')
        time.sleep(1)
        with open('/hello/world.txt','r') as f:
            print(f.read())

        t = 0
        while t <= 200000000:
            t*t
            t += 1
        print('finished intensive process')
