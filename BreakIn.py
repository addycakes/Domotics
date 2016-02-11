import time
from apns import APNs, Frame, Payload
import sys
import os

#commands coming from arduinos will have two arguments
#one for which room the breakin happened in
#another for the opening that was breached

#get room name
roomName = sys.argv[1]
#get the opening
openingName = sys.argv[2]

#create instance of APNS
apns = APNs(use_sandbox=True, cert_file='FilePath.pem', key_file='FilePath.pem')

# devices to receive notification
keys = ['iphone hex token']

#create message
message = "Break in: " + roomName + ':' + openingName + '!'

#Break In
payload = Payload(alert=message, sound="default", badge=1)

#Send to all device keys
for key in keys:
    apns.gateway_server.send_notification(key, payload)
