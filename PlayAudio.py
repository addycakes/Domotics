import os
import time
import sys

#all audio files are kept in a directory.  PlayAudio.py is called with one argument, the filepath
#to a specific audio file.

#get filePath
filePath = sys.argv[1]

command = "aplay -D sysdefault:CARD=ALSA " + filePath + ".wav&"
os.system(command)

