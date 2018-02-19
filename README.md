# BreakThePony
Santa sent a [Crazepony Mini](http://www.crazepony.com/products/mini.html) down the chimney this Christmas. Either I was a bad boy, or I'm not living up to the 14-year-old drone pilot inside me.  The quadcopter is uncontrollable.  Here is my first step in wrangling the quadcopter from my MacBook.

## Project Overview
The XCode project BreakThePony listens to the local [Bluetooth LE](https://en.wikipedia.org/wiki/Bluetooth_Low_Energy) connection for a device with description beginning with "Crazepony" to establish telnet connections pass commands to and sensor readings from the quadcopter.

The decision to split the quadcopter connection functionality from everything else stems in neglect of updating the [Bluecove Java Bluetooth implementation](http://bluecove.org/) to modern versions of Mac OS X and BLE, and from my discomfort/displeasure with Swift and XCode.

See project XXX for monitoring and visualization of quadcopter readings and .... project YYY

## Telnet Commands
All telnet commands and responses are assumed to terminate in "\r\n".

### get
Upon receiving "get" the server will respond with a string in the form "sensor-id-0: value-0, sensor-id-1: value-1, ... sensor-id-n: value-n" and close the connection.

### put
Upon receiving "put" the server will wait for a string of the form "power-value-0, power-value-1, ..." and close the connection.

### str
"str" causes the server to stream sensor readings to the client.  Once read, the server will send strings in the form of "sensor-id-i: value-i" as they are read. Clean termination is not currently implemented.

### alt
"alt" spins off a thread to alternate sending quadcopter state strings of the form sent by get and waiting for a power assignment string used in the put command. Clean termination is not currently implemented.

## Todos
- Decode sensor readings...
- Graphical monitoring, for separate project.... dump to postgres and read with Grafana?
- Simple navigation/hold attitude command, for a separate project.
