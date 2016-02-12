import time
import uinput
import os

#restart mumble server to ensure a stable connection
os.system("sudo service mumble-server restart")

time.sleep(40) #allow time for pi to start up

#this gives uinput the capabilities it needs to simulate keyboard
os.system("sudo modprobe uinput") 

def main():
    #list of all keys to be used
    events = (
        uinput.KEY_A,
        uinput.KEY_ENTER
        )

    device = uinput.Device(events)
    time.sleep(3) # This is required here only for demonstration
                      # purposes. Without this, the underlying machinery might
                      # not have time to assign a proper handler for our device
                      # before the execution of this script reaches the end and
                      # the device is destroyed. At least this seems to be the
                      # case with X11 and its generic event device
                      # handlers. Without this magical sleep, "hello" might not
                      # get printed because this example exits before X11 gets
                      # its handlers ready for processing events from this
                      # device.
                      
    device.emit_click(uinput.KEY_ENTER) #connect to server
    
    time.sleep(25) #wait for server to connect and ask for password

    #password
    device.emit_click(uinput.KEY_A)
    
    #connect to server
    device.emit_click(uinput.KEY_ENTER) 

if __name__ == "__main__":
    main()

