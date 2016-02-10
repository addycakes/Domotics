#!/usr/bin/python
import alsaaudio, time, audioop

'''
libraries needed:
apt-get install python-alsaaudio

config sound card:      (stops device from reporting busy when not in use)
sudo nano /etc/modprobe.d/alsa-base.conf
change 'options snd-usb-audio index=-2' to 'options snd-usb-audio index=0'

'''

# Set attributes: Mono, 8000 Hz, 16 bit little endian samples
inp = alsaaudio.PCM(alsaaudio.PCM_CAPTURE, alsaaudio.PCM_NONBLOCK, 'sysdefault:CARD=Camera')
inp.setchannels(1)
inp.setrate(8000)
inp.setformat(alsaaudio.PCM_FORMAT_S16_LE)
inp.setperiodsize(320)

volMAX = 0
while volMAX < 9000:    #volume threshold for breaking loop
    # Read data from device
    l,data = inp.read()
    if l:
        # Return the maximum of the absolute value of all samples in a fragment.
        volMAX = audioop.max(data, 2)
    time.sleep(.01)

doSomething()

