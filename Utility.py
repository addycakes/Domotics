import plistlib
import time
import datetime
import httplib

fileName = ''
fileNameRaw = ''

#open existing plists
utilityPL = plistlib.readPlist(fileName)
rawDataPL = plistlib.readPlist(fileNameRaw)

#connec to arduino and read utilities
h1 = httplib.HTTPConnection('url')
h1.request("GET", "/arduino/utility/0")
r1 = h1.getresponse()
text = r1.read()

#parse response
values = text.split('\n')
for value in values:
    if not value == '':
        item = value.split(' ')
        if values.index(value) == 0:
            current = item[0]
        else:
            total = item[0]
 
#plist dicts
EngCons_ = utilityPL['EngCons']
WaterCons_ = utilityPL['WaterCons']
SolarGen_ = utilityPL['SolarGen']
WindGen_ = utilityPL['WindGen']
EngConsRaw = utilityPL['EngCons']
WaterConsRaw = utilityPL['WaterCons']
SolarGenRaw = utilityPL['SolarGen']
WindGenRaw = utilityPL['WindGen']

#format plists
EngCons_['Current']  = current
day = EngCons_['Day']
week = EngCons_["Week"]
month = EngCons_["Month"]
year = EngCons_["Year"]

#get current hour and minute
time = datetime.datetime.now()
hour = int(time.strftime("%H"))
minute = int(time.strftime("%M"))
mm = int(time.strftime("%m"))
dd = int(time.strftime("%d"))
yy = int(time.strftime("%Y"))

#check if hour is up
if (minute + 5 >= 60):
    if len(day) == 24:
        day.remove(day[0])
    day.append(total)
    EngCons_['Day'] = day
    
#check if day is  up
if (hour == 24) and (minute + 5 >= 60):
    if len(week) == 7:
        week.remove(week[0])
    week.append(total)
    EngCons_['Week'] = week

    #check if month is up
    if (((mm == 2) and ( dd == 28)) or ((mm in [4,6,9,11]) and (dd == 30)) or (dd == 31)):       
        dTotal = 0
        for d in month:
            dTotal += int(d)
            
        #check if month is full
        if len(month) == 30:
            month.remove(month[0])
        month.append(total)
        EngCons_['Month'] = month
       
	#check if year is full     
        if len(year) == 12:
            year.remove(year[0])
        year.append(dTotal)
        EngCons_['Year'] = year

    #add day totals to UtilityRAW.plist
    key = str(mm) +str(dd) +str(yy)
    EngConsRaw[key] = total

#save dictionaries as plist       
pl = dict(
    EngCons=EngCons_,
    WaterCons=WaterCons_,
    SolarGen=SolarGen_,
    WindGen=WindGen_,
)
pl2 = dict(
    EngCons=EngConsRaw,
    WaterCons=WaterConsRaw,
    SolarGen=SolarGenRaw,
    WindGen=WindGenRaw,
)

plistlib.writePlist(pl, fileName)
plistlib.writePlist(pl2, fileNameRaw)

