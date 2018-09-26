To create a new task for the website to kick off, you must do the following:

Create a directory with the name of your task under 'coregrapher_v2> app > subjob'
In that directory, you will need 'myapp.py', please use the example given in this directory, only
substituting 'from .ts import TemplateSubJob' to 'from .<your script> import <your class>' and
any reference to 'TemplateSubJob' and 'ts' with whatever you are using.

in '<your script>.py', bare bones you need:
------------------------
import app
from app.helper import ws_send

class <your class>:
    def __init__(self, sessiondata, sid, payload):
        self.session = sessiondata
        self.sid = sid
        self.payload = payload

    def startme(self):
        # in order to send messages to the user(like you would normally use print), you can use ws_send() which is a helper
        # function that sends an emit to the websocket, to whoever ran the job.
        ws_send(self.sid, self.payload, 'Send some output to the user...')
        # optionally return xls bytes output to be emailed to the user.  You can use xlsxwriter module to get this output
        # please see coregrapher_v2 > app > subjob > coregrapher > printoutput.py for an example.
------------------------

You will need to add the following to 'coregrapher_v2 > app > templates > index.html'

<body><tr><td><select><option value="<<name of your directory>>"><<name of your directory>></option></select><td></body>


<body><tr><td><div id="<<name of your directory>>" style="display:none">

PUT STUFF YOU WANT TO PROMPT USER FOR HERE

eg.
            <div id="coregrapher" style="display:none">
                Coregrapher will generate an xlsx file of a specific account's information.<br>
                Fields include: <br>
                Device,Name,Nickname,DataCenter,Platform,Status,Primary IP,Private IP,Additional IP's,Network,Segment,Network Type,Switch Name,Switch Port,Interface Speed,Interface Status,Vlans,Learned_Macs,Downlink_Port-->Uplink_Port/Neighbor Switch <br>
                Enter Account Number:<input name="coregrapher.account" id="coregrapher.account" type="text"><br>
                Pull from Core?<input id="coregrapher.pull" name="coregrapher.pull" checked="checked" type="checkbox"><br>
                Force update if data exists in coregrapher cache?<input id="coregrapher.force" name="coregrapher.force" type="checkbox"><br>
            </div>

</div></td></tr></body>
