__author__ = 'laurentmeyer'
# Set the command type to auto
import sys, telnetlib, time
MOCK_SERVER = "192.168.2.217"
MOCK_SERVER_PORT = 35000

def beginCommunication(telnetaddr = MOCK_SERVER, telnetport = MOCK_SERVER_PORT):
    telnet = telnetlib.Telnet(telnetaddr, port=telnetport)
    return telnet

def startInfiniteLoop(telnetConnection):
    if telnetConnection is not None:
        getRPM(telnetConnection)
        fuelGals(telnetConnection)
        getTheFirstTemperature(telnetConnection)
        getSpeedOfCar(telnetConnection)
        getFuelPressure(telnetConnection)

def getRPM(telnet):
    telnet.write(b"010C")
    time.sleep(0.2)
    output = telnet.read_eager()
    output = output.splitlines()
    oBytes = output[1].split(b' ')
    dataString = oBytes[4]+oBytes[5]
    # The rpm is given multiplied by 4.
    value = int(dataString, 16)/4
    print("RPM: "+str(value))

def getSpeedOfCar(telnet):
    telnet.write(b"010d")
    time.sleep(0.2)
    output = telnet.read_eager()
    output = output.splitlines()
    oBytes = output[1].split(b' ')
    dataString = oBytes[len(oBytes)-1]
    value = int(dataString, 16)
    print ("Speed: "+ str(value)+" km/h")

def getTheFirstTemperature(telnet):
    telnet.write(b"0105")
    time.sleep(0.2)
    output = telnet.read_eager()
    output = output.splitlines()
    oBytes = output[1].split(b' ')
    dataString = oBytes[len(oBytes)-1]
    value = int(dataString, 16)-40
    print ("Engine coolant temp: "+str(value))

# Seems quite complicated, have to be real tested
def getEgt(telnet):
    pass

def fuelGals(telnet):
    telnet.write(b"0107")
    time.sleep(0.2)
    output = telnet.read_eager()
    output = output.splitlines()
    oBytes = output[1].split(b' ')
    dataString = oBytes[len(oBytes)-1]
    value = ((int(dataString, 16)-128)*100/128)
    print ("Fuel: "+ str(value)+" %")

def getFuelPressure(telnet):
    telnet.write(b"010a")
    time.sleep(0.2)
    output = telnet.read_eager()
    output = output.splitlines()
    oBytes = output[1].split(b' ')
    dataString = oBytes[len(oBytes)-1]
    value = int(dataString, 16)*3
    print ("Fuel pressure: "+str(value) + " kPa")


if __name__ == '__main__':
    if (sys.argv.__len__()==2):
        telnetaddr = sys.argv[1]
        telnetport = sys.argv[2]
        telnetConnection = beginCommunication(telnetaddr = telnetaddr, telnetport = telnetport)
    else:
        telnetConnection = beginCommunication()
    startInfiniteLoop(telnetConnection)