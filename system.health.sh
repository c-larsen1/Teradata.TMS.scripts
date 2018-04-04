#!/bin/bash
## Created by c-larsen1 for automatic system health reporting...
## Please do not run script if you're not sure...

# Version = 00.00.00.01
# 2017-06-02 c-larsen1 - Initial version/draft
#
# Version = 00.00.00.02
# 2017-07-19 c-larsen1 - Fixed cron - command path - issues
#
# Version = 00.00.00.03
# 2017-07-25 c-larsen1 - Added Active Directory (LDAP) test
#
# Version = 01.00.00.04
# 2017-08-03 c-larsen1 - Emp into production - changed version numbering
#                           - Added DNS test
#                           - Added NTP test
#                           - Added AMP test
#
# Version = 01.00.00.05
# 2017-08-07 c-larsen1 - Added CMIC version
#
# Version = 01.00.00.06
# 2017-08-21 c-larsen1 - Added DAMC list
#
# Version = 01.00.00.07
# 2017-08-31 c-larsen1 - Added DAMC health status
#
# Version = 01.00.00.07a
# 2018-01-31 c-larsen1 - Fix DAMC health output...
#                           - Issues needs fix - No proper Array Drive fault detection
#                                              - No proper Array Controller fault detection
#                                              - No DOT HILL support
#
# Version = 01.00.00.08
# 2018-02-16 c-larsen1 - Added Kerberos - Keyfile
#                                            - Gethost
#                                            - KVNO
#
# Version = 01.00.00.08a
# 2018-02-23 c-larsen1 - Fixed some scripting problems
#
# Version = 01.00.00.08b
# 2018-03-22 c-larsen1 - Added internal node disks status
#
##########################################################################################################

SYSTEMNAME=$(cat /etc/HOSTNAME)
#LOGFILE=/home/support/system.health.scripts/export/$SYSTEMNAME.system.health.report.$(date +'%b%d-%Y.%H%M').log
LOGFILE=$(cat system.health.cfg | grep LOGFOLDER | cut -d'=' -f2)/$SYSTEMNAME.system.health.report.log
#CHKALLLOG=/home/support/system.health.scripts/export/$SYSTEMNAME.chk_all.$(date +'%b%d-%Y.%H%M').log
VCONFIG=/etc/opt/teradata/tdconfig/vconfig.txt

echo ""
echo ""
echo "Automatic system health reporting..."
echo "Please do not run script if you're not sure..."
echo "Version = 01.00.00.08b"

echo $(date) "System Health Report for - $SYSTEMNAME:" > $LOGFILE
echo "Version = 01.00.00.08b" >> $LOGFILE
echo "" >> $LOGFILE

echo "System info:" >> $LOGFILE
/opt/teradata/gsctools/bin/machinetype | grep "Model:" -A9 > /tmp/shs.systeminfo.log
cat /tmp/shs.systeminfo.log >> $LOGFILE
rm /tmp/shs.systeminfo.log
echo "" >> $LOGFILE

echo "CMIC Version:" >> $LOGFILE
/opt/teradata/gsctools/bin/get_cmic_version > /tmp/cmic.ver.txt
cat /tmp/cmic.ver.txt >> $LOGFILE
rm /tmp/cmic.ver.txt
echo "" >> $LOGFILE

echo "System has:" >> $LOGFILE
echo $(cat /etc/opt/teradata/tdconfig/mpplist | grep byn00 | wc -l) "nodes" >> $LOGFILE
echo "" >> $LOGFILE

echo "System mpp list:" >> $LOGFILE
cat /etc/opt/teradata/tdconfig/mpplist | grep byn00 > /tmp/shs.mpplist.log
cat /tmp/shs.mpplist.log >> $LOGFILE
 cut -d' ' -f1 /tmp/shs.mpplist.log > /tmp/bynet.list.column.txt
 tr '\n' ' ' < /tmp/bynet.list.column.txt > /tmp/bynet.list.row.txt ; echo "" >>  /tmp/bynet.list.row.txt
rm /tmp/shs.mpplist.log
rm /tmp/bynet.list.column.txt
echo "" >> $LOGFILE

echo "PDE Status:" >> $LOGFILE
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh /opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/pdestate -a > /tmp/shs.pdestate.log
cat /tmp/shs.pdestate.log >> $LOGFILE
rm /tmp/shs.pdestate.log
echo "" >> $LOGFILE

echo "Display down AMPs:" >> $LOGFILE
/opt/teradata/tdat/tdbms/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/vprocmanager -g | egrep 'AMP |RSG |GTW |TVS |PE ' | grep -v 'ONLINE' | grep -v 'Vproc  Rel.' > /tmp/down.amps.txt
cat /tmp/down.amps.txt >> $LOGFILE
 # Checking if file is empty - if it is empty then echo the ok.
 if [[ -s /tmp/down.amps.txt ]]
    then echo "*****There are Down AMPs*****" >> $LOGFILE
    else echo "All AMPs seems to be ONLINE" >> $LOGFILE
 fi
rm /tmp/down.amps.txt
echo "" >> $LOGFILE

echo "Date:" >> $LOGFILE
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh /bin/date > /tmp/shs.date.log
cat /tmp/shs.date.log >> $LOGFILE
rm /tmp/shs.date.log
echo "" >> $LOGFILE

echo "NTP status:" >> $LOGFILE
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "/usr/sbin/ntpq -p | grep '*'" > /tmp/ntp.server.status.log
 # sed $ removes empty lines s and g teplace string with string
cat /tmp/ntp.server.status.log | sed '/^$/d' | sed 's/---------------------//g' | sed 's/-----------//g' | sed 's/</-/g' | sed 's/>//g' >> $LOGFILE
rm /tmp/ntp.server.status.log
echo "" >> $LOGFILE

echo "System dumps:" >> $LOGFILE
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/csp -mode list > /tmp/shs.csp.log
cat /tmp/shs.csp.log >> $LOGFILE
rm /tmp/shs.csp.log
echo "" >> $LOGFILE

echo "Database start time:" >> $LOGFILE
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/tpatrace -s | grep PDE > /tmp/shs.trace.log
cat /tmp/shs.trace.log >> $LOGFILE
rm /tmp/shs.trace.log
echo "" >> $LOGFILE

echo "DNS Test:" >> $LOGFILE
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "ping -c1 google.com | grep PING" > /tmp/dns.test.log
cat /tmp/dns.test.log >> $LOGFILE
rm /tmp/dns.test.log
echo "" >> $LOGFILE

echo "Active Directory Logon Test:" >> $LOGFILE
/opt/teradata/tdat/tdgss/$(rpm -qa | grep tdgss | sort | tail -1 | cut -d'-' -f2)/bin/tdsbind -u SA23360003 -w $(cat /etc/lp.dat) >> $LOGFILE
echo "" >> $LOGFILE

echo "Kerberos Key List:" >> $LOGFILE
/usr/lib/mit/bin/klist -ke /etc/teradata.keytab | grep -i cop > /tmp/krlist.out.txt
cat /tmp/krlist.out.txt >> $LOGFILE
echo "" >> $LOGFILE

echo "Kerberos Authentication Test:" >> $LOGFILE
#for i in $(/usr/lib/mit/bin/klist -ke /etc/teradata.keytab | grep -i cop | sed -e 's/^[[:space:]]*//' | cut -d' ' -f2 | cut -d'@' -f1) ; do /usr/lib/mit/bin/kvno $i ; done >> $LOGFILE
/usr/bin/printf $(cat /etc/lp.dat) | /usr/lib/mit/bin/kinit SA23360003
sleep 2
for i in $(cat /tmp/krlist.out.txt | sed -e 's/^[[:space:]]*//' | cut -d' ' -f2 | cut -d'@' -f1) ; do /usr/lib/mit/bin/kvno $i ; done > /tmp/krlist.out.2.txt
cat /tmp/krlist.out.2.txt >> $LOGFILE
echo "" >> $LOGFILE

echo "GetHost output for Kerberos:" >> $LOGFILE
for i in $(cat /tmp/krlist.out.2.txt | cut -d' ' -f1 | cut -d'/' -f2 |  cut -d'@' -f1)
 do /opt/teradata/client/15.10/bin/gethost -c $i
#done | egrep 'SMP00|Teradata Host Servers|cop|SPN|TERADATA' > /tmp/krlist.out.3.txt
done | egrep 'SMP0|cop|TERADATA' > /tmp/krlist.out.3.txt
cat /tmp/krlist.out.3.txt >> $LOGFILE
echo "" >> $LOGFILE

echo "Array - DAMC list:" >> $LOGFILE
#/usr/bin/SMcli -d | grep DAMC | cut -d' ' -f1 > /tmp/DAMC.list.txt
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "/usr/bin/SMcli -d | grep DAMC | cut -d' ' -f1" | sed '/^$/d' | grep -v "byn" | grep -v "nodes" > /tmp/DAMC.list.txt
cat /tmp/DAMC.list.txt >> $LOGFILE
echo "" >> $LOGFILE

echo "Internal Disk status:" >> $LOGFILE
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "/opt/dell/srvadmin/bin/omreport storage pdisk controller=0 | egrep 'ID|Status|State' | grep -v ' Status' | grep -v 'RAID' | grep -v ' ID'" > /tmp/node.drives.txt
cat /tmp/node.drives.txt >> $LOGFILE
rm /tmp/node.drives.txt
echo "" >> $LOGFILE

echo "Array - Health:" >> $LOGFILE
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "/usr/bin/SMcli -d -v" > /tmp/SM.output.health.txt
cat /tmp/SM.output.health.txt >> $LOGFILE
cat /tmp/SM.output.health.txt | sed '/SMcli completed successfully/d' | sed '/^$/d' | awk '!/byn0/' | grep 'Needs Attention' | cut -d' ' -f1 > /tmp/faulty.array.list.txt
while read in ; do SMcli -n "$in" -c 'show storageArray healthStatus;' ; done < /tmp/faulty.array.list.txt >> $LOGFILE
rm /tmp/faulty.array.list.txt

#cat /tmp/DAMC.list.txt | while read ARDAMLIST
# do
#  echo $ARDAMLIST >> $LOGFILE
#  /opt/teradata/osutils/bin/sallsh "SMcli -n $ARDAMLIST -c 'show storageArray healthStatus;'" > /tmp/DAMC.output.per.array.txt
#  cat /tmp/DAMC.output.per.array.txt | grep "Executing script..." -A100 > /tmp/DAMC.output.per.array.ext.txt
#  sed -i '/^$/d' /tmp/DAMC.output.per.array.ext.txt
#  grep -v "Script execution complete." /tmp/DAMC.output.per.array.ext.txt > /tmp/DAMC.output.per.array.ext1.txt
#  grep -v "SMcli completed successfully." /tmp/DAMC.output.per.array.ext1.txt > /tmp/DAMC.output.per.array.ext2.txt
#  grep -v "Executing script..." /tmp/DAMC.output.per.array.ext2.txt > /tmp/DAMC.output.per.array.ext3.txt
#  cat /tmp/DAMC.output.per.array.ext3.txt >> $LOGFILE
#  rm /tmp/DAMC.output.per.*.txt
#  sleep 1
# done
#rm /tmp/DAMC.list.txt
echo "" >> $LOGFILE

##Running chk_all and extracting
echo "Errors from chk_all script:" >>$LOGFILE
/opt/teradata/gsctools/bin/chk_all
cp /var/opt/teradata/gsctools/chk_all/chk_all.txt /tmp/shs.chk_all.txt.full
cat /tmp/shs.chk_all.txt.full | grep "TEST SUMMARY:" -A50 > /tmp/shs.greped.chk_all.txt
awk '1;/====/{exit}' /tmp/shs.greped.chk_all.txt >> $LOGFILE
rm /tmp/shs.chk_all.txt.full
rm /tmp/shs.greped.chk_all.txt
echo "" >> $LOGFILE

##Running node.check and extracting
echo "Errors from node.check script:" >>$LOGFILE
/home/support/node.check -c -f /home/support/system.health.scripts/export/node.check $(cat /tmp/bynet.list.row.txt)
rm /tmp/bynet.list.row.txt
cat /home/support/system.health.scripts/export/node.check >> $LOGFILE
rm /home/support/system.health.scripts/export/node.check.cpio.gz
rm /home/support/system.health.scripts/export/node.check

#scp to remote server
#scp $LOGFILE root@10.144.179.102:/home/support/system.health.scripts/import/

##Cleanup - uncomment it you want to delete LogFile
#rm $LOGFILE

