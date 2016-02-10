import plistlib
import time
import datetime
import httplib
import os

#hosts for data: arduino ip
h1 = httplib.HTTPConnection('url')
h2 = httplib.HTTPConnection('url')

#filePath
fileName = ''

#Empty dictionaries for plist
_Utility = {}
_Kitchen = {}
_Garage = {}
_Occupied = False

def unpackStatuses(statuses):
   #arduino status RESt sends tuples
   # ( roomName, item, state )
   global _Occupied
   for tup in statuses:
      if not tup == '':
         room,item,state = tup.split(',')
         if 'Utility' in room:_Utility[item]=state.strip()
         if 'Kitchen' in room:_Kitchen[item]=state.strip()
         if 'Garage' in room:_Garage[item]=state.strip()
         if 'Home' in room:_Occupied=state.strip()
            
def addCamsToRooms():
   Camera = {}
   Camera2 = {}
   Camera3 = {}
   Camera4 = {}
   Camera5 = {}

   Camera["Name"]="DeckCam"
   Camera["Url"]=""
   Camera["hasControls"]=True
   Camera2["Name"]="YardCam"
   Camera2["Url"]=""
   Camera2["hasControls"]=False
   Camera3["Name"]="SophieCam"
   Camera3["Url"]=""
   Camera3["hasControls"]=True
   Camera4["Name"]="GarageCam"
   Camera4["Url"]=""
   Camera4["hasControls"]=False
   Camera5["Name"]="BackGateCam"
   Camera5["Url"]=""
   Camera5["hasControls"]=False

   _Kitchen["Cams"] = [Camera,Camera3]
   _Garage["Cams"] = [Camera4, Camera5]
   _Utility["Cams"] = [Camera2]

#connect to arduinos
h1.request("GET", "/arduino/status/0")
r1 = h1.getresponse()
text = r1.read()
s = text.split('\n')

h2.request("GET", "/arduino/status/0")
r2 = h2.getresponse()
text2 = r2.read()
s2 = text2.split('\n')

#read responses
unpackStatuses(s2)                
unpackStatuses(s)
addCamsToRooms()

#This is the basic structure to be coordinated with
#Domotics Floor xib file
houseDict = dict(
   Kitchen=_Kitchen,
   Garage=_Garage,
   Utility=_Utility)

pl = dict(
    MainFloor=houseDict,
    Occupied =_Occupied
    )

plistlib.writePlist(pl, fileName)
