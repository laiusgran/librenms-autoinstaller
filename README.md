# librenms-autoinstaller
## Auto installer of the open source program LibreNMS
### Feel free to use the script or fork it.


## How to use it:
Clone it first and add execute permissions:
```
git clone https://github.com/laiusgran/librenms-autoinstaller
chmod +x librenms-autoinstaller/*
```
Inside the script you can some variables (I will mention them later). 
When you run it (run it as root), you will be prompt with the following questions (there is no input validation, so make sure you write it correctly):

### Write the network that will be able to access the database, ex: 192.168.34.% 
-For security reasons, you should limit which subnet or IP can access the database. If you want to access it through a different computer/server you can include the network. 

-Example, if your librenms and server are in the 10.10.10.0/24 network, you can write : 10.10.10.% 

-Every equipment from 10.10.10.1-254 can access the database. 

-LibreNMS defaults it to 'localhost' so only LibreNMS can access the database, this is useful in situations where you only have 1 LibreNMS and as such, you should write localhost 
   
  
   
### Write database username. On LibreNMS Docs the default would be  librenms 
-You won't be using the username anyway so you can leave it  librenms 
 
### Write the database password 
-The password is for the username written in the question before. LibreNMS defaults it to password so you should change to something more creative. 
 
 
### Write Local Server IP 
-Since this isntallation is standalone, you should write the IP address of the machine you are installing in. \
-Do not put localhost, this address is used to setup the HTTP website. 
 
 
### Write SNMP Community 
-So you can poll the machine itself. 
 
 
 ## LibreNMSStandAlone
Bash script installer of the LibreNMS following the Docs: \
https://docs.librenms.org/Installation/Install-LibreNMS/

The installer does not use the cron job. It uses the Dispatcher Service: \
https://docs.librenms.org/Extensions/Dispatcher-Service/
 
## LibreNMSCentral 
This script installs the Database, Redis, RRDCached, HTTP on the same machine, thats why I call it Central. \
If you don't want to install everything on the same machine, then use the standalone script (it installs database+librenms). Then install what you want by your own means. 
 
Again, this install does not use the cron job. It uses the Dispatcher Service: \
https://docs.librenms.org/Extensions/Dispatcher-Service/ 

### How to use it

Inside the script you can edit the following parameters:
Timezone.
Redis port.
Redis server IP-
Database IP.
When you run it (run it as root), you will be prompt with the following questions (there is no input validation, so make sure you write it correctly):


