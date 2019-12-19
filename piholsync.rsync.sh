#!/bin/bash -x
#  README
:'
Version 2.1.1
-----------------------------
Credit to redditor /u/jvinch76  https://www.reddit.com/user/jvinch76 for creating the basis for this modification.
-----------------------------
Original Source https://www.reddit.com/r/pihole/comments/9gw6hx/sync_two_piholes_bash_script/
Previous Pastebin https://pastebin.com/KFzg7Uhi
-----------------------------
Reddit link https://www.reddit.com/r/pihole/comments/9hi5ls/dual_pihole_sync_20/
-----------------------------
Improvements:  check for existence of files before rsync and skip if not present, allow for remote command to be run 
without password by adding ssh keys to remote host no longer require hard coding password in this script, HAPASS removed.
-----------------------------
2.1.1 Changes - add directions for complete n00bs who never use the root account. (Pre Install Steps)
-----------------------------
Credit for Origonal version
/u/jvinch76
-----------------------------
Credit for V2
/u/LandlordTiberius
-----------------------------
Me
/u/ShawnEngland
-----------------------------

#VARS
FILES=(black.list blacklist.txt regex.list whitelist.txt lan.list) #list of files you want to sync
PIHOLEDIR=/etc/pihole #working dir of pihole
PIHOLE2=192.168.88.4 #IP of 2nd PiHole
HAUSER=root #user of second pihole
 
#LOOP FOR FILE TRANSFER
RESTART=0 # flag determine if service restart is needed
for FILE in ${FILES[@]}
do
  if [[ -f $PIHOLEDIR/$FILE ]]; then
  RSYNC_COMMAND=$(rsync -ai $PIHOLEDIR/$FILE $HAUSER@$PIHOLE2:$PIHOLEDIR)
    if [[ -n "${RSYNC_COMMAND}" ]]; then
      # rsync copied changes
      RESTART=1 # restart flagged
     # else
       # no changes
     fi
  # else
    # file does not exist, skipping
  fi
done
 
FILE="adlists.list"
RSYNC_COMMAND=$(rsync -ai $PIHOLEDIR/$FILE $HAUSER@$PIHOLE2:$PIHOLEDIR)
if [[ -n "${RSYNC_COMMAND}" ]]; then
  # rsync copied changes, update GRAVITY
  ssh $HAUSER@$PIHOLE2 "sudo -S pihole -g"
# else
  # no changes
fi

#DHCP Files

FILE="/etc/dnsmasq.d/04-pihole-static-dhcp.conf"
RSYNC_COMMAND=$(rsync -ai $FILE $HAUSER@$PIHOLE2:$FILE)
if [[ -n "${RSYNC_COMMAND}" ]]; then
  # rsync copied changes, update GRAVITY
  ssh $HAUSER@$PIHOLE2 "pihole -g"
# else
  # no changes
fi

FILE="/etc/dnsmasq.d/02-pihole-dhcp.conf"
RSYNC_COMMAND=$(rsync -ai $FILE $HAUSER@$PIHOLE2:$FILE)
if [[ -n "${RSYNC_COMMAND}" ]]; then
  # rsync copied changes, update GRAVITY
  ssh $HAUSER@$PIHOLE2 "pihole -g"
# else
  # no changes
fi
 
if [ $RESTART == "1" ]; then
  # INSTALL FILES AND RESTART pihole
ssh $HAUSER@$PIHOLE2 "sudo -S service pihole-FTL restart"
fi
