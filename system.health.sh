#!/bin/bash
## Created by c-larsen1 for automatic system health reporting...
## https://github.com/c-larsen1
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
#                      - Issues needs fix - No proper Array Drive fault detection
#                                         - No proper Array Controller fault detection
#                                         - No DOT HILL support
#
# Version = 01.00.00.08
# 2018-02-16 c-larsen1 - Added Kerberos - Keyfile
#                                       - Gethost
#                                       - KVNO
#
# Version = 01.00.00.08a
# 2018-02-23 c-larsen1 - Fixed some scripting problems
#
# Version = 01.00.00.08b
# 2018-03-22 c-larsen1 - Added internal node disks status
#
# Version = 01.00.00.09
# 2018-03-22 c-larsen1 - Fixed presentation
#
##########################################################################################################

SYSTEMNAME=$(cat /etc/HOSTNAME)
#LOGFILE=/home/support/system.health.scripts/export/$SYSTEMNAME.system.health.report.$(date +'%b%d-%Y.%H%M').log
LOGFILE=$(cat /etc/system.health.cfg | grep LOGFOLDER | cut -d'=' -f2)/$SYSTEMNAME.system.health.report.log
CHKALLLOG=/home/support/system.health.scripts/export/$SYSTEMNAME.chk_all.$(date +'%b%d-%Y.%H%M').log
VCONFIG=/etc/opt/teradata/tdconfig/vconfig.txt
SCPUSER=$(cat /etc/system.health.cfg | grep USER | cut -d'=' -f2)
SERVERREMOTE=$(cat /etc/system.health.cfg | grep REMOTESCPSERVER | cut -d'=' -f2)
SERVERREMOTEFOLDER=$(cat /etc/system.health.cfg | grep REMOTESERVERFOLDER | cut -d'=' -f2)
USERAD=$(cat /etc/system.health.cfg | grep ADUSELDAPR | cut -d'=' -f2 | cut -d' ' -f1 | tr -d '\n')
URLDNS=$(cat /etc/system.health.cfg | grep DNSURL | cut -d'=' -f2 | tr -d '\n')
COMMAND1=$(if [[ "$(cat /etc/system.health.cfg | grep ENABLESCP | cut -d'=' -f2)" == 'yes' ]] ; then echo "scp $LOGFILE $SCPUSER@$SERVERREMOTE:$SERVERREMOTEFOLDER" ; else echo "" ; fi)
COMMAND2=$(if [[ "$(cat /etc/system.health.cfg | grep ENABLESCP | cut -d'=' -f2)" == 'yes' ]] ; then echo "rm $LOGFILE" ; else echo "echo Document is availible in at $LOGFILE" ; fi)

echo ""
echo ""
echo "Automatic system health reporting..."
echo "Please do not run script if you're not sure..."
echo "Version = 01.00.00.09"

echo $(date) "System Health Report for - $SYSTEMNAME:" > $LOGFILE
echo "Version = 01.00.00.09" >> $LOGFILE
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
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "ping -c1 $URLDNS | grep PING" > /tmp/dns.test.log
cat /tmp/dns.test.log >> $LOGFILE
rm /tmp/dns.test.log
echo "" >> $LOGFILE

echo "Active Directory Logon Test:" >> $LOGFILE
/opt/teradata/tdat/tdgss/$(rpm -qa | grep tdgss | sort | tail -1 | cut -d'-' -f2)/bin/tdsbind -u $USERAD -w $(cat /etc/lp.dat) >> $LOGFILE
echo "" >> $LOGFILE

echo "Kerberos Key List:" >> $LOGFILE
/usr/lib/mit/bin/klist -ke /etc/teradata.keytab | grep -i cop > /tmp/krlist.out.txt
cat /tmp/krlist.out.txt >> $LOGFILE
echo "" >> $LOGFILE

echo "Kerberos Authentication Test:" >> $LOGFILE
#for i in $(/usr/lib/mit/bin/klist -ke /etc/teradata.keytab | grep -i cop | sed -e 's/^[[:space:]]*//' | cut -d' ' -f2 | cut -d'@' -f1) ; do /usr/lib/mit/bin/kvno $i ; done >> $LOGFILE
/usr/bin/printf $(cat /etc/lp.dat) | /usr/lib/mit/bin/kinit $USERAD
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

echo "Internal Disk status:" >> $LOGFILE
if [[ "$(/opt/teradata/gsctools/bin/machinetype | grep NodeVendor | cut -d' ' -f5 | cut -d'=' -f2)" == 'DELL' ]]
 then /opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "/opt/dell/srvadmin/bin/omreport storage pdisk controller=0 | egrep 'ID|Status|State' | grep -v ' Status' | grep -v 'RAID' | grep -v ' ID'" /tmp/node.drives.txt
 else /opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "/opt/MegaRAID/CmdTool2/CmdTool2 -LDPDInfo -a0 | egrep 'State |Virtual Drive'" > /tmp/node.drives.txt
fi
cat /tmp/node.drives.txt >> $LOGFILE
rm /tmp/node.drives.txt
echo "" >> $LOGFILE
/opt/MegaRAID/CmdTool2/CmdTool2 -LDPDInfo -a0 | egrep 'State |Virtual Drive'

echo "Array - DAMC list:" >> $LOGFILE
#/usr/bin/SMcli -d | grep DAMC | cut -d' ' -f1 > /tmp/DAMC.list.txt
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "/usr/bin/SMcli -d | grep DAMC | cut -d' ' -f1" | sed '/^$/d' | grep -v "byn" | grep -v "nodes" > /tmp/DAMC.list.txt
cat /tmp/DAMC.list.txt >> $LOGFILE
echo "" >> $LOGFILE

echo "Array - Health:" >> $LOGFILE
/opt/teradata/tdat/pde/$(/usr/pde/bin/pdepath -i | grep PDE: | cut -d' ' -f2)/bin/psh "/usr/bin/SMcli -d -v" | sed '/SMcli completed successfully/d' | sed '/^$/d' > /tmp/SM.output.health.txt
cat /tmp/SM.output.health.txt >> $LOGFILE
cat /tmp/SM.output.health.txt | awk '!/byn0/' | grep 'Needs Attention' | cut -d' ' -f1 > /tmp/faulty.array.list.txt
if [[ -s /tmp/faulty.array.list.txt ]]
 then echo -e "\n*****There are Faults in the Arrays*****\n       Fauilty Array list...\n$(cat /tmp/faulty.array.list.txt)\n"
 else echo -e "\nAll Array are Healthy...\n"
fi >> $LOGFILE
while read in
 do SMcli -n "$in" -c 'show storageArray healthStatus;'
 done < /tmp/faulty.array.list.txt | sed '/Performing syntax check.../d' | sed '/Syntax check complete./d' | sed '/Executing script.../d' | sed '/Script execution complete./d' | sed '/SMcli completed successfully./d' | sed '/The controller clocks/d' | sed '/Controller/d' | sed '/Storage Management Station/d' | sed '/^$/d' >> $LOGFILE
rm /tmp/faulty.array.list.txt

echo "" >> $LOGFILE

$COMMAND1

##Cleanup
$COMMAND2
