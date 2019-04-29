#!/bin/bash
##############################################################################
# $Id: $
# Boot from Gentoo CDRom and then run this script on the target system
# Programs that are assumed to be on the boot image are:
# awk bunzip2 cat dialog fdisk grep parted tar sed
# Also requires the proc filesystem to be operational.
# All GPL2 licensed, m'Kay?
##############################################################################
#
# Installation process overview:
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# After LiveCD has booted and hardware has been detected, this and only this
# script is run.
#
# Steps:
# 1.  Check feasibility of installing to the target computer
# 2.  Partition disk
# 3.  Mount partitions
# 4.  Copy installation images to mount points
# 5.  Chroot to the mount points
# 6.  Configure environment configuration
# 7.  Reboot
#
# Running the Installation:
# ~~~~~~~~~~~~~~~~~~~~~~~~
#  - like so:
# $ export LINES
# $ export COLUMNS
# $ InstallDistro.sh
#
# Configuration:
# ~~~~~~~~~~~~~
# 1. The IDE drive on the Ultra5. For now it will only work if it is the
#    primary master drive, since Ultra5 need to be boot from /dev/hda1
#    which is supported by the onboard IDE controller.
DISK="/dev/hda"
# 2. Default host name - you will be asked if you want to change it
#    during the install
HOSTNAME=$(hostname)
# 3. Distro Title - will be changed by the Install creator, MakeDistro,sh:
DISTROTITLE="BigNose Linux 2008.11"
RELEASE_NAME="The European Swallow"
#    Background text
BACKTITLE="${DISTROTITLE} Installation for SUN Ultra5/10 SPARC II 64-bit computers"
# 4. Duration of info boxes in seconds
SLEEP=3
# 5. Log file
LOG="/tmp/install.log"
# 6. Gentoo mount point
GENTOO="/mnt/gentoo"
# 7. Default status in the background header
STATUS="CHROOTING"
# 8. Number of new users so far
NUMNEWUSERS=0

##############################################################################
# Programs:
# ~~~~~~~~
export PATH=.:$PATH
DIALOG="dialog"
THIS=$(basename $0)

##############################################################################
# Cleanup:
# ~~~~~~~
# Remove critical remnants on a crash
PASSWD="/tmp/.passwd"
INPUT="/tmp/.input"
touch $INPUT
trap "ExitInstall" EXIT INT TERM HUP

# Exiting operation - remove all temp files
# Show abort message unless set in the final stage of the install to success
function ExitInstall {
  DEBUG "ExitInstall"
  rm -fr $PASSWD
  rm -fr ${INPUT}*
  rm -fr ${GENTOO}/tmp/${THIS}
  $DIALOG --title "Exiting..." --backtitle "${BACKTITLE} - ${STATUS}" --aspect 65 --infobox "${EXITMESSAGE}" 0 0
  exit
}

#============================================================================#
# Diagnostics
#============================================================================#
function DEBUG {
  TS=$(date '+%Y.%m.%d %H:%M:%S')
  printf "$TS DEBUG " >> $LOG
  while [[ -n $1 ]] ; do
    printf "$1 " >>  $LOG
    shift
  done
  printf "\n" >> $LOG
}

# Death to the evil function for it must surely die!
# Unambiguous program exit
# Parameters:  optional error message
# Exit Code:   1
function DIE {
  DEBUG "DIE $*"
  if [[ -z ${1} ]]; then
    MSG="Failed."
  else
    MSG="${1}"
  fi
  $(sleep ${SLEEP})|$DIALOG --title "Aborting..." --backtitle "$BACKTITLE"  --aspect 65 --infobox "$MSG" 0 0
  tail ${LOG}
  exit 1
}


#============================================================================#
# Dialog functions
#============================================================================#
# Error Dialog with message.
# Note:       Lines longer than 72 chars will be broken up in sometimes
#             unpredictable ways.
# Returns:    0 if user selected to exit. The calling code needs to exit.
# Parameters: Error message
# Example:    ErrorDlg "iwconfig not found" && exit 1 || return 1
function ErrorDlg {
  DEBUG "ErrorDlg $1"
  TITLE="ERROR"
  MSG="${1}

Do you want to exit?"
  $DIALOG --title "$TITLE" --backtitle "${BACKTITLE} - ${TITLE}" --yesno "$MSG" 0 0
  return $?
}

# Warning Dialog with message.
# Note:       Lines longer than 72 chars will be broken up in sometimes
#             unpredictable ways.
# Returns:    0 if user selected to exit. The calling code needs to exit.
# Parameters: Warning message
# Example:    WarningDlg "iwconfig not found" && exit 1 || return 1
function WarningDlg {
  DEBUG "WarningDlg $1"
  TITLE="WARNING"
  MSG="${1}

Do you want to exit?"
  $DIALOG --title "$TITLE" --backtitle "${BACKTITLE} - ${TITLE}"  --yesno "$MSG" 0 0
  return $?
}

# Info Dialog with message. Times out. User can't close it
# Parameters: Info message
# Example:    InfoDlg "eth0 is now configured"
function InfoDlg {
  DEBUG "InfoDlg $1"
  TITLE="INFO"
  MSG="${1}"
  [[ -z $MSG ]] && return 1
  $(sleep ${SLEEP})|$DIALOG --title "$TITLE" --backtitle "${BACKTITLE} - ${STATUS}" --aspect 65 --infobox "$MSG" 0 0
}

# Flash Dialog with message. Times out after 1 second. User can't close it
# Parameters: Info message
# Example:    InfoDlg "eth0 is now configured"
function FlashDlg {
  DEBUG "FlashDlg ${1} ${2}"
  TITLE="INFO"
  MSG="${1}"
  [[ -z $MSG ]] && return 1
  $(sleep 1)|$DIALOG --title "${1}" --backtitle "${BACKTITLE} - ${STATUS}" --aspect 65 --infobox "${2}" 0 0
}


# Dialog box with Yes / No as options.
# Parameters: Title
#             Message
# Returns:    0 if yes
#             1 if No
#             255 if Esc or Ctrl-C
# Example:    YesNoDlg "Question" "Are you sure?"
#             echo $?
function YesNoDlg {
  DEBUG "YesNoDlg $1"
  TITLE="${1}"
  MSG="${2}"
  $DIALOG --title "$TITLE" --backtitle "${BACKTITLE} - ${STATUS}" --aspect 65 --no-collapse --yesno "$MSG" 0 0
  return $?
}

# Display percentage progress guage that
# Examples:   process &
#             ProgressDlg "Process progress" 10
#             wait
#   or
#             $(process >> $LOG 2>&1) | GaugeDlg "Process" 10
# Parameters: 1 Display message
#             2 ESTIMATED duration in seconds
function GaugeDlg {
  TITLE="$1"
  interval=$(echo ${2} | awk '{print $1 / 100}')
  { for i in $(seq 1 100); do  echo "$i"; sleep $interval; done } | dialog --title "$TITLE" --backtitle "${BACKTITLE} - ${STATUS}" --gauge "${MSG}" 5 70 0
}

# Display running log file output in a tail -f style
# The dialog does not stop when the process has finished -
# the user needs to hit Enter to see if it is done.
# Examples:   process >> $LOG &
#             TailDlg "Process Title" "$LOG"
#             wait
#   or
#             $(process >> $LOG 2>&1) | TailDlg "Process" $LOG
# Parameters: 1 Display Message
#             2 File Name
# Returns:    0 EXIT pressed
#             1 Ctrl-C pressed
#             255 ESC pressed
function TailDlg {
  TITLE="$1"
  LOGFILE="$2"
  # Prevent error in case file does not exist
  [[ ! -a $LOGFILE ]] && touch $LOGFILE
  # Max Dialog size based on a 25x80 screen if values not available
  [[ -z $LINES ]] && Y=21 || Y=$((LINES-4))
  [[ -z $COLUMNS ]] && X=70 || X=$((COLUMNS-10))
  EXITTITLE="Running"
  $DIALOG --title "${TITLE}" --exit-label "$EXITTITLE" --backtitle "${BACKTITLE} - ${STATUS}" --tailbox "$LOGFILE" $Y $X
  RETCODE=$?
  # Wait for background job to finish
  EXITTITLE="Still running"
  while : ; do
    if [[ $(jobs | wc -l) -gt 0 ]]; then
      EXITTILE="Done"
      break
    fi
    EXITTITLE="${EXITTITLE}.."
    $DIALOG --title "${TITLE}" --exit-label "$EXITTITLE" --backtitle "${BACKTITLE} - ${STATUS}" --tailbox "$LOGFILE" $Y $X
    RETCODE=$?
    # User hit Ctrl-C:
    if [[ $RETCODE -eq 1 ]]; then
      EXITTILE="User cancelled"
      kill -9 %1 >/dev/null 2>&1
      sleep 1
      kill -9 %1 >/dev/null 2>&1
      break
    fi
  done
  $DIALOG --title "${TITLE}" --exit-label "$EXITTITLE" --backtitle "${BACKTITLE} - ${STATUS}" --tailbox "$LOGFILE" $Y $X
  return $RETCODE
}

# Parameter:  1. Progress box title
#             2. Process description (optional)
# Example:    $ cat /var/log/message | tee -a $LOG | ProgressDlg "Test" "Process Name"
function ProgressDlg {
  TITLE="$1"
  DESC="$2"
  # Max Dialog size based on a 25x80 screen if values not available
  [[ -z $LINES ]] && Y=21 || Y=$((LINES-8))
  [[ -z $COLUMNS ]] && X=72 || X=$((COLUMNS-12))
  #DEBUG "$DIALOG --title \"${TITLE}\" --backtitle \"${BACKTITLE}\" --progressbox \"${DESC}\" $Y $X"
  $DIALOG --title "${TITLE}" --backtitle "${BACKTITLE} - ${STATUS}" --progressbox "${DESC}" $Y $X
}

# Display a message in a dialog box untilthe user clicks OK
# Paramters:  1 Title
#             2 Message
function MessageDlg {
  DEBUG "MessageDlg $1"
  TITLE="$1"
  MSG="$2"
  $DIALOG --title "$TITLE" --aspect 50 --no-collapse --backtitle "${BACKTITLE} - ${STATUS}" --msgbox "$MSG" 0 0
  return $?
}

# Input box
# Parameters:     1 Title
#                 2 Message
#                 3 (Optional) Save parameter name. This is appended to $INPUT
# Output:         $(cat ${INPUT}.savename) to get the Input value
# Returns:        0 if OK pressed
function InputDlg {
  DEBUG "InputDlg $*"
  [[ -n $3 ]] && VALFILE=${INPUT}.${3} || VALFILE=${INPUT}
  $DIALOG --title "$1" --aspect 50 --no-collapse --backtitle "${BACKTITLE} - ${STATUS}" --inputbox "$2" 0 0 2>${VALFILE}
  return $?
}

#============================================================================#
# File read & write fumctions
#============================================================================#

# Set config value in file (= separation)
# Parameters:   Filepath
#               parameter
#               value
# Example:      /etc/conf.d/hostname HOSTNAME beavis
#               adds/updates: HOSTNAME="beavis"
function SetConfigValueEquals {
  DEBUG "Setting ${1}: ${2}=${3}"
  [[ ! -a "${1}" ]] && touch "${1}"
  grep "^${2}" "${1}" >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    if [[ ${3:0:1} = "(" ]]; then
      sed -i -e "s/^\($2\)=.*/\1=$3/" "${1}" >/dev/null 2>&1
    else
      sed -i -e "s/^\($2\)=.*/\1=\"$3\"/" "${1}" >/dev/null 2>&1
    fi
  else
    ADDDATE=$(date +%Y.%m.%d)
    grep "Added on $ADDDATE" $1 >/dev/null 2>&1
    [[ $? -ne 0 ]] && printf "# Added on $ADDDATE:\n" >> ${1}
    if [[ ${3:0:1} = "(" ]]; then
      printf "${2}=${3}\n" >> $1
    else
      printf "${2}=\"${3}\"\n" >> $1
    fi
  fi
}

# Set config item in file (tab or space separation)
# Parameters:   Filepath parameter value
# Example:      /etc/hosts 127.0.0.1 "beavis beavis.hoekstra.co.uk localhost.localdomain localhost"
#               adds/updates: 127.0.0.1   beavis beavis.hoekstra.co.uk localhost.localdomain localhost
function SetConfigValueTab {
  DEBUG "SetConfigValueTab ${1}: ${2} ${3}"
  [[ ! -a "${1}" ]] && touch "${1}"
  grep "^${2}" "${1}" >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    sed -i -e "s/^\s*\(${2}\)\s\s*.*/\1\t${3}/" "${1}" >/dev/null 2>&1
  else
    ADDDATE=$(date +%Y.%m.%d)
    grep "Added on $ADDDATE" $1 >/dev/null 2>&1
    [[ $? -ne 0 ]] && printf "# Added on $ADDDATE:\n" >> ${1}
    printf "${2}\t${3}\n" >> $1
  fi
}

# Parameters: Filepath
#             Keyword
# Output:     Prints the corresponding value to stdout
# Returns:    0 if keyword found
#             1 if invalid keyword specified
#             2 if invalid filepath specified
function GetConfigValueEquals {
  DEBUG "GetConfigValueEquals $*"
  [[ ! -a $1 ]] && return 2
  LINE=$(grep ${2} ${1} 2>/dev/null)
  [[ -z $LINE ]] && return 1
  VALUE=$(echo $LINE | sed -e 's/..*=//' -e 's/"//g')
  DEBUG "GetConfigValueEquals $1 $2 $VALUE"
  echo $VALUE
}
function GetConfigValueTab {
  DEBUG "GetConfigValueTab $*"
  [[ ! -a $1 ]] && return 2
  LINE=$(grep ${2} ${1} 2>/dev/null)
  [[ -z $LINE ]] && return 1
  VALUE=$(echo $LINE | awk '{print $2}' | sed -e 's/^"//g' | sed -e 's/"$//g')
  DEBUG "GetConfigValueTab $1 $2 $VALUE"
  echo $VALUE
}

#============================================================================#
# HARDWARE TECHNICAL
#============================================================================#

# Checking environment and memory
function ShowComputerSpecs {
  DEBUG "ShowComputerSpecs"
  # Memory:
  MEMORY=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  MSG="Memory: ${MEMORY} kb"

  # CPU:
  # For AMD CPU's, this is how the /proc/cpuinfo works
  CPU=$(grep "^model name" /proc/cpuinfo | sed -e 's/.*: //')
  # For SPARC CPU's, this is how the /proc/cpuinfo works
  [[ -z $CPU ]] && CPU=$(grep "^cpu" /proc/cpuinfo | sed -e 's/.*: //')
  # Not known
  [[ -z $CPU ]] && CPU="Unknown"

  # Disk:
  # General disk size description, i.e. 40.0GB
  DISKSIZEDESC=$(parted /dev/hda print 2>/dev/null | grep Disk | awk '{print $3}')
  MessageDlg "Your Computer's Specification" "You are about to install to a computer
with the following capabilities:

CPU:        ${CPU}
Memory:     ${MEMORY} kB
Disk size:  ${DISKSIZEDESC} on ${DISK}

This installation only deals with ${DISK}
and other disks need to be manually
configured for after the installion.

"
}

# Show disk space usage for all mounted partitions
function ShowDiskUsage {
  DEBUG "ShowDiskUsage"
  result=$(df -k | grep $DISK | awk '{disk+=$2
  avail+=$4}\
END { mb_avail = avail / 1024
  gb_avail = mb_avail / 1000
  mb_disk = disk / 1024
  gb_total = mb_disk / 1000
  util = ((mb_disk-mb_avail) / mb_disk ) * 100
  printf "%.0fMB (%.2fGB) out of a total of\n%.0fMB (%.2fGB) is available.\n\n%.0f%% utilisation",\
          mb_avail, gb_avail,mb_disk,gb_total,util
}')
  TITLE="Total disk usage for $DISK"
  if [[ -z $result ]]; then
    MSG="Hard disk '$DISK' has not yet been mounted."
    MsgDlg "$TITLE" "$MSG"
    return 1
  else
    (echo $result | cut -d' ' -f 12 | sed -e 's/%//' ; sleep ${SLEEP}) | $DIALOG --title "${TITLE}" \
      --backtitle "$BACKTITLE" --guage "$result" 10 44
    return 0
  fi
}

#============================================================================#
# Disk partitioning
#============================================================================#

# Shows the partition sizes of all mounted hard disk partitions
function ShowPartitionSizes {
  DEBUG "ShowPartitionSizes"
  MessageDlg "Disk partitions" "The hard disk ${DISK} is partitioned and mounted as follows:

`df -mT ${DISK}* | grep -v cdrom | grep -v tmpfs | grep -v udev | grep -v loop`

Swap
` grep ${DISK} /proc/swaps | awk '{print $1" Size: "$3/1024" MB"}'`
"
}

# Calculate and Show sizes of existing partitions
# Output to STDERR:   ROOTSIZE
#                     SWAPSIZE
#                     USRSIZE
#                     VARSIZE
#                     HOMESIZE
# Returns:            0 Success
#                     1 Failure
function CalcPartitionSizes {
  DEBUG "CalcPartitionSizes"
  DISKSIZEMBYTES=$(parted ${DISK} print 2>/dev/null | grep $DISK | awk '{print $3}' | sed -e 's/\..*GB//' | awk '{print $1 * 1000}')
  # Calculating required swap size;
  #   2 x available RAM, up to 2GB, then 1 to 1.
  #   Never less than 64M
  MEMORY=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}' | sed -e 's/\..*//')
  if [[ $MEMORY -gt 2000 ]]; then
    SWAPSIZE=$(echo $MEMORY | awk '{print 2000+$1}')
  else
    SWAPSIZE=$(echo $MEMORY | awk '{print $1*2}')
  fi
  if [[ $MEMORY -lt 32 ]]; then
    SWAPSIZE=64
  fi

  # Calculating partition sizes. There are the absolute Minimum sizes in MB:
  ROOTSIZE=500
  USRSIZE=2200
  VARSIZE=500
  HOMESIZE=512

  # Get minimum disk size
  MIMREQSIZEMBYTES=$(echo "$ROOTSIZE $SWAPSIZE $USRSIZE $VARSIZE $HOMESIZE" | awk '{print $1+$2+$3+$4+$5}')
  if [[ $MIMREQSIZEMBYTES -gt $DISKSIZEMBYTES ]]; then
     ErrorDlg "Your hard disk is too small to install '${DISTROTITLE}' on.

You need at least ${MIMREQSIZEMBYTES} MB, but you only have ${DISKSIZEMBYTES} MB.
Get a larger IDE disk on the primary master IDE interface of your motherboard.
Note that other disks on other IDE interfaces are not considered during this
installation and need to be manually configured for after this installation." && exit 1

    WarningDlg "You have chosen to continue the install, even though there appears to
be insufficient diskspace. Chances are pretty high that the installation
of '${DISTROTITLE}' will fail.

The minimum required partition sizes are:

    ${DISK}1 ${ROOTSIZE} MB for root
    ${DISK}2 ${SWAPSIZE} MB for swap
    ${DISK}4 ${USRSIZE} MB for usr
    ${DISK}5 ${VARSIZE} MB for var
    ${DISK}6 ${HOMESIZE} MB for home
    Total Req ${MIMREQSIZEMBYTES} MB
    Available ${DISKSIZEMBYTES} MB" && exit 1
  fi

  # Optimize disk sizing
  AVAILABLESIZEMB=$((DISKSIZEMBYTES-MIMREQSIZEMBYTES))
  # Expand usr partition to no more than 10 GB
  if [[ $AVAILABLESIZEMB -ge 100 ]]; then
    if [[ $AVAILABLESIZEMB -ge 10000 ]]; then
      if [[ $AVAILABLESIZEMB -ge 20000 ]]; then
        if [[ $AVAILABLESIZEMB -ge 30000 ]]; then
          if [[ $AVAILABLESIZEMB -ge 40000 ]]; then
            USRSIZE=$((USRSIZE+4000))
            AVAILABLESIZEMB=$((AVAILABLESIZEMB-4000))
          else
            USRSIZE=$((USRSIZE+3000))
            AVAILABLESIZEMB=$((AVAILABLESIZEMB-3000))
          fi
        else
          USRSIZE=$((USRSIZE+2000))
          AVAILABLESIZEMB=$((AVAILABLESIZEMB-2000))
        fi
      else
        USRSIZE=$((USRSIZE+1000))
        AVAILABLESIZEMB=$((AVAILABLESIZEMB-1000))
      fi
    else
      USRSIZE=$((USRSIZE+AVAILABLESIZEMB))
      AVAILABLESIZEMB=0
    fi
  fi
  # Expand var partition a bit
  if [[ $AVAILABLESIZEMB -ge 100 ]]; then
    if [[ $AVAILABLESIZEMB -ge 500 ]]; then
      if [[ $AVAILABLESIZEMB -ge 1000 ]]; then
        VARSIZE=$((VARSIZE+1000))
        AVAILABLESIZEMB=$((AVAILABLESIZEMB-1000))
      else
        VARSIZE=$((VARSIZE+500))
        AVAILABLESIZEMB=$((AVAILABLESIZEMB-500))
      fi
    else
      VARSIZE=$((VARSIZE+AVAILABLESIZEMB))
      AVAILABLESIZEMB=0
    fi
  fi
  # Expand the home partition to the end of the disk
  HOMESIZE=$(echo "$DISKSIZEMBYTES $ROOTSIZE $SWAPSIZE $USRSIZE $VARSIZE" | awk '{print $1-$2-$3-$4-$5}')
  YesNoDlg "Disk Partitioning of ${DISK}" "Hard disk ${DISK} will be partitioned as follows:

Total disk size:
    ${DISK}  ${DISKSIZEMBYTES} MB
Partitions:
    ${DISK}1 $ROOTSIZE MB for root
    ${DISK}2 $SWAPSIZE MB for swap
    ${DISK}3 ${DISKSIZEMBYTES} MB for whole disk
    ${DISK}4 $USRSIZE MB for usr
    ${DISK}5 $VARSIZE MB for var
    ${DISK}6 $HOMESIZE MB for home

Note:
${DISK}3 is a 'whole-disk' partition and is required by Sun hardware.

Press 'Yes' to continue or 'No' to abort this installation."
  RETCODE=$?
  if [[ $RETCODE -eq 0 ]]; then
    printf "$ROOTSIZE $SWAPSIZE $USRSIZE $VARSIZE $HOMESIZE\n" 1>&2
    return 0
  else
    DIE "User chose to abort the installation"
  fi
}

# Removes all partitions from disk $DISK
# This is done before chrooting to the newly installed environment
# Parameters: None
# Returns:    0 success
#             1 failed
# Example:    RemoveAllDiskPartitions | ProgressDlg "Removing disk partitions"
function RemoveAllDiskPartitions {
  DEBUG "RemoveAllDiskPartitions"
  # Remove all real paritions in descending order
  # If there is a full-disk partition 3, then it will not remove
  # this partition with `parted`
  i=0
  while : ; do
    PARTITIONS=($(fdisk $DISK -l |  awk '{print $1}' | grep $DISK | sort -r))
    [[ ${#PARTITIONS[*]} -eq 0 ]] && break
    # Make regex for /dev/hda --> \/dev\/hda
    REXDISK=$(echo ${DISK} | sed -e "s|\/|\\\/|g")
    for PARTITION in ${PARTITIONS[*]}; do
      PARTITIONID=$(echo $PARTITION | sed -e "s/${REXDISK}//g")
      DEBUG "Dropping partition $PARTITIONID on $DISK...\n"
      printf "Dropping partition $PARTITIONID on $DISK...\n"
      parted ${DISK} rm ${PARTITIONID} 1>/dev/null 2>&1
    done
    i=$((i+1))
    if [[ $i -eq 4 ]]; then
      DEBUG "Failed to remove all paritions.
The following partitions are still present on ${DISK}:

$(fdisk $DISK -l |  awk '{print $1}' | grep $DISK | sort -r)

You could manually attempt to remove these paritions using
a program like fdisk and them restart this installation."
      break
    fi
    sleep 1
  done
}

# Checks if the whole disk partition is present and deletes it
# of the users chooses to
# Creates its OWN PROGRESS DIALOGS
# Parameters: None
# Returns:    0 success
#             1 failed
function RemoveWholeDiskPartition {
  DEBUG "RemoveWholeDiskPartition:"
  # Remove full-disk partition if one is still there.
  PARTITIONS=($(fdisk $DISK -l |  awk '{print $1}' | grep ${DISK}3))
  if [[ ${#PARTITIONS[*]} -gt 0 ]]; then
    # The full-disk partition is still present - remove it for good measure?
    YesNoDlg "Remove Full-disk Partition on ${DISK}" "The full-disk partition on ${DISK} still exists.
You can choose to remove it now and to recreate it
later on again, or you can leave it just like this.
Do you want to drop this partition?"
    YN=$?
    if [[ $YN -eq 0 ]]; then
      i=0
      while : ; do
        # User is in a beliggerent mood and wants to destroy all partitions! So let him.
        printf "d\n3\nw\nq\n" > ${INPUT}killpartition3
        fdisk ${DISK} < ${INPUT}killpartition3  2>&1 | tee -a $LOG | ProgressDlg "Removing full-disk partition" "Please wait..."
        PARTITIONS=($(fdisk $DISK -l |  awk '{print $1}' | grep ${DISK}3))
        [[ -z $PARTITIONS ]] && break
        i=$((i+1))
        if [[ $i -eq 3 ]]; then
          InfoDlg "Failed to delete partitin ${DISK}3.
Probably best leave it then. The installation will use it in
any case later on."
          break;
        fi
        sleep $SLEEP
      done
    fi
  fi
  return 0
}

# Makes all partitions EXCEPT for the SUN whole disk partitions
# Parameters: disk partition sizes in MB:
#             1 Partition 1 /
#             2 Partition 2 swap
#             3 Partition 4 /usr
#             4 Partition 5 /var
#             5 Partition 6 /home
# Example:    CreateAllPartitions | ProgressDlg "Creating disk partitions" "This may take a while..."
function CreateAllPartitions {
  DEBUG "CreateAllPartitions $*"
  ROOTSIZE=$1
  SWAPSIZE=$2
  USRSIZE=$3
  VARSIZE=$4
  HOMESIZE=$5

  # Boundaries:
  B1=$ROOTSIZE
  B2=$((B1+SWAPSIZE))
  B3=$((B2+USRSIZE))
  B4=$((B3+VARSIZE))
  B5=$((B4+HOMESIZE))

  while : ; do
    printf "Creating partitions:\n"
    DEBUG "parted -s ${DISK} mkpart ext2 0 $B1"
    parted -s ${DISK} mkpart ext2 0 $B1
    sleep $SLEEP
    DEBUG "parted -s ${DISK} mkpart linux-swap $B1 $B2"
    parted -s ${DISK} mkpart linux-swap $B1 $B2
    sleep $SLEEP
    DEBUG "parted -s ${DISK} mkpart ext2 $B2 $B3"
    parted -s ${DISK} mkpart ext2 $B2 $B3
    sleep $SLEEP
    DEBUG "parted -s ${DISK} mkpart ext2 $B3 $B4"
    parted -s ${DISK} mkpart ext2 $B3 $B4
    sleep $SLEEP
    DEBUG "parted -s ${DISK} mkpart ext2 $B4 $B5"
    parted -s ${DISK} mkpart ext2 $B4 $B5
    sleep $SLEEP

    printf "Checking that all partitions were created..."
    fdisk $DISK -l | grep ^${DISK}
    COUNT=$( fdisk $DISK -l | grep ^${DISK} | wc -l )
    if [[ $COUNT -lt 6 ]]; then
      printf "$((6-COUNT)) partitions were not created. Trying again...\n"
      RemoveAllDiskPartitions
    else
      break
    fi
  done

  printf "Setting boot partition:\n"
  DEBUG "parted /dev/hda set 1 boot on"
  parted -s ${DISK} set 1 boot on

  printf "Journalling the partitions:\n"
  DEBUG "mke2fs ${DISK}1"
  mke2fs ${DISK}1
  [[ $? -eq 0 ]] && printf "done\n" || printf "failed\n"
  DEBUG "mke2fs -j ${DISK}4"
  mke2fs -j ${DISK}4
  [[ $? -eq 0 ]] && printf "done\n" || printf "failed\n"
  DEBUG "mke2fs -j ${DISK}5"
  mke2fs -j ${DISK}5
  [[ $? -eq 0 ]] && printf "done\n" || printf "failed\n"
  DEBUG "mke2fs -j ${DISK}6"
  mke2fs -j ${DISK}6
  [[ $? -eq 0 ]] && printf "done\n" || printf "failed\n"
}

# Create Whole Disk SUN Disk label on partition 3
# Also creates partition 1 and 2, the sizes of which are useless
# and therefore need to be removed again.
# Parameters: 1. Cylinders
#             2. Heads
#             3. Sectors/track
function CreateSUNDiskLabel {
  DEBUG "CreateSUNDiskLabel $*"
  # First check that there are no partitions
  if [[ -n $(fdisk -l $DISK | grep Number) ]]; then
    ErrorDlg "Hard disk ${DISK} is not empty. Can't create whole disk partition." && \
    exit 1 || return 1
  fi

  printf "Create 'SUN disklabel' virtual partition:\n"
  printf "s\n0\n${2}\n${3}\n${1}\n\n\n\n\n\nw\n" > makepartition3
  fdisk ${DISK} < makepartition3
  printf "d\n1\nw\nq\n" > killpartition1
  printf "Drop partition 1:\n"
  fdisk ${DISK} < killpartition1
  printf "d\n2\nw\nq\n" > killpartition2
  printf "Drop partition 2:\n"
  fdisk ${DISK} < killpartition2
  return 0
}

# Checks exiting disk partitions and asks the user if he want to keep them
# Parameters: None
# Returns:    0 There are no partitions.
#             1 User chose to Delete existing partitions
#             2 User chose to Keep existing partitions
function CheckExistingDiskPartition {
  DEBUG "CheckExistingDiskPartition $*"
  # Checking partitions on $DISK
  REXDISK=$(echo ${DISK} | sed -e "s|\/|\\\/|g")
  PARTITIONS=($(parted $DISK print | grep "^ [1-9]" | sed -e "s/^ /$REXDISK/g" | awk '{print $1"  "$4"X"}'))

  PARTNUM=${#PARTITIONS[*]}
  PARTNUM=$((PARTNUM/2))
  case "${PARTNUM}" in
    ##############################################
    '0' )
      # No partitions
      YesNoDlg "Analysis of ${DISK}" "Hard disk ${DISK} has not yet been partitioned.

Hit 'Yes' to start the partitioning process.
Remember that all data on ${DISK} will be
lost in this process.

Hit 'No' to cancel the installation."
      YN=$?
      [[ $YN -ne 0 ]] && DEBUG "YES pressed - overwrite all data in  hard disk" || DEBUG "NO pressed - exit"
      if [[ $YN -eq 0 ]]; then
        # Yes  - overwrite all data in  hard disk
        return 0
      else
        # No - exit
        DIE "User chose to abort the installation"
      fi
      return 0
      ;;
    ##############################################
    '1' )
      DEBUG "fdisk -l $DISK | grep Whole 1>/dev/null 2>&1"
      fdisk -l $DISK | grep Whole 1>/dev/null 2>&1
      if [[ $? -eq 0 ]]; then
        MessageDlg "Partitioning of hard disk ${DISK}" "Hard disk ${DISK} only has a SUN whole disk partition.
This will be left intact."
      else
        MessageDlg "Partitioning of hard disk ${DISK}" "The only partition is:

$(echo ${PARTITIONS[*]} | sed -e 's/X/\n/g' | sed -e 's/^ //')

Hard disk ${DISK} will be repartitioned."
      fi
      return 0
      ;;
    ##############################################
    '5' )
      # Got correct 5 partitions
      YesNoDlg "Partitioning hard disk ${DISK}"  "The existing partitions are:

$(echo ${PARTITIONS[*]} | sed -e 's/X/\n/g' | sed -e 's/^ //')


The hard disk ${DISK} appears to be partitioned
correctly already, although the sizing may not be
optimal.

You can either repartition ${DISK} (suggested) or
attempt to continue the installation on this
partition scheme if you know what you are doing.

Do you want to repartition hard disk ${DISK}?"
    YN=$?
      if [[ $YN -eq 0 ]]; then
        # Yes: User chose to Delete existing partitions
        return 1
      else
        # No: User chose to Keep existing partitions
        YesNoDlg "Keep existing Partitions" "The installation can continue using the existing
partitions but the result is not going to be entirely
deterministic. Presumably you know what you are doing.
Or just being silly. Anyway, the hard disk ${DISK}
will be overwritten and there is no guarantee that
the existing data on ${DISK} will remain intact.

Are you sure you want to continue and keep the
following partitions?

$(echo ${PARTITIONS[*]} | sed -e 's/X/\n/g' | sed -e 's/^ //')

If you hit 'No', the installation will exit and you
can restart it with the command:

  $  ${THIS}

If you hit 'Yes', the installation will reformat ONLY
those partitions that are not of the correct file
system type. The partitions that will be reformatted
WILL HAVE THEIR CONTENT OVERWRITTEN."
        YN=$?
        [[ $YN -ne 0 ]] && DEBUG "YES pressed - keep partitions" || DEBUG "NO pressed - exit"
        if [[ $YN -eq 0 ]]; then
          # Yes  - keep partitions
          return 2
        else
          # No - exit
          DIE "User chose to abort the installation"
        fi
      fi
      ;;
    ##############################################
    * )
      MessageDlg "Analysis of ${DISK}" "The existing partitions are:

$(echo ${PARTITIONS[*]} | sed -e 's/X/\n/g' | sed -e 's/^ //')

Hard disk ${DISK} has an invalid number of
partitions and will be repartitioned."
      return 1
      ;;
  esac
}

# Unmount harddisk partitions off /mnt/gentoo and turn swap partition off
# Parameters: None
# Usage:      UnmountPartitions | ProgressDlg "Mounting partitions"
# Returns:    0 if all partitions were unmounted
#             1 if one or more unmounts failed
function UnmountPartitions {
  DEBUG "UnmountPartitions"
  SWAPPARTITION=$(grep partition /proc/swaps | head -1 | awk {'print $1'})
  if [[ -n $SWAPPARTITION ]]; then
    DEBUG "Turning off swap partition $SWAPPARTITION on ${DISK}2..."
    DEBUG "swapoff -a"
    swapoff -a
    [[ $? -ne 0 ]] && DEBUG "Failed to turn off swap partition $SWAPPARTITION.\n" || printf "done\n"
  else
    DEBUG "No swapping partitions found"
  fi

  DEBUG "umount /mnt/gentoo/proc"
  umount /mnt/gentoo/proc 2>/dev/null
  DEBUG "umount -O bind /mnt/gentoo/dev"
  umount -O bind /mnt/gentoo/dev 2>/dev/null

  # Get all partitions and unmount
  PARTITIONS=(`mount | grep "$DISK" | awk {'print $1'} | sort -r ` )
  for PARTITION in ${PARTITIONS[*]}; do
    DEBUG "Attempt 1 - unmount partition ${PARTITION}..."
    DEBUG "umount ${PARTITION}"
    umount ${PARTITION} 2>/dev/null
  done
  sleep 1
  PARTITIONS=(`mount | grep "$DISK" | awk {'print $1'} | sort -r` )
  for PARTITION in ${PARTITIONS[*]}; do
    DEBUG "Attempt 2 - unmount partition ${PARTITION}..."
    DEBUG "umount ${PARTITION}"
    umount ${PARTITION} 2>/dev/null
  done
  sleep 1
  PARTITIONS=(`mount | grep "$DISK" | awk {'print $1'} | sort -r ` )
  for PARTITION in ${PARTITIONS[*]}; do
    DEBUG "Attempt 3 - unmount partition ${PARTITION}..."
    DEBUG "umount ${PARTITION}"
    umount ${PARTITION} 2>/dev/null
  done
  sleep 1
  PARTITIONS=(`mount | grep "$DISK" | awk {'print $1'} | sort -r ` )
  if [[ -z $PARTITIONS ]]; then
    DEBUG "All partitions on ${DISK} unmounted."
    return 0
  else
    DEBUG "Failed to unmount partition(s) ${PARTITIONS[*]}.\n"
    return 1
  fi
  return 0
}


# Tries really hard to mount a partition of a particular file system
# type and no other type
# Parameters: partition, e.g. /dev/hda4
#             mount point, e.g.  /mnt/gentoo/usr
#             fstype, e.g. ext3. Special cases exist for proc and bind
# Returns:    0 success
#             1 wrong file system type
#             2 partition does not exist
#             3 mount point does not exist and could not be created
function MountPartition {
  DEBUG "MountPartition $1 $2 $3"
  if [[ ${1} != none ]]; then
    if [[ ${3} != bind ]]; then
      printf "Checking if partition exists..."
      DEBUG "fdisk ${DISK} -l | grep ${1} >/dev/null 2>&1"
      fdisk ${DISK} -l | grep ${1} >/dev/null 2>&1
      [[ $?  -ne 0 ]] && printf "failed.\nExiting..." && return 2
      printf "done\n"
    fi
  fi

  printf "Checking mount point ${2}..."
  if [[ ! -d "${2}" ]]; then
    printf "does not exist yet\n"
    printf "mkdir ${2}..."
    DEBUG "mkdir "${2}" >/dev/null 2>&1"
    mkdir "${2}" >/dev/null 2>&1
    [[ $? -eq 0 ]] && printf "done\n" || printf "failed\n"
  else
    printf "already exists\n"
  fi


  if [[ ${1} != none ]]; then
    if [[ ${3} != bind ]]; then
      printf "Checking file system of ${1}..."
      PARTNUM=$(echo "${1}" | sed -e "s|$DISK||")
      FSTYPE=$(parted ${DISK} print | grep "^ $PARTNUM" | awk '{print $5}')
      if [[ $FSTYPE != ${3} ]]; then
        printf "${FSTYPE} is not the required ${3}.\nFormatting ${1}..."
        case "${3}" in
          ext2 )
            DEBUG "mke2fs ${1} >/dev/null 2>&1"
            mke2fs "${1}" >/dev/null 2>&1
            [[ $? -ne 0 ]] && printf "could not format ${1}\n" && return 1
            ;;
          ext3 )
            DEBUG "mke2fs -j ${1} >/dev/null 2>&1"
            mke2fs -j "${1}" >/dev/null 2>&1
            [[ $? -ne 0 ]] && printf "could not format ${1}\n" && return 1
            ;;
        esac
        printf "done\n"
      fi
    fi
  fi

  printf "Mounting ${1} on ${2}...\n"
  ATTEMPT=0
  while : ; do
    if [[ ${3} = bind ]]; then
      DEBUG "mount ${1} ${2} -o ${3}"
      mount ${1} ${2} -o ${3} >/dev/null 2>&1
    else
      DEBUG "mount ${1} ${2} -t ${3}"
      mount ${1} ${2} -t ${3} >/dev/null 2>&1
    fi
    [[ $? -eq 0 ]] && break
    printf "failed.\nTrying again...\n"
    sleep $SLEEP
    if [[ ${3} != bind ]]; then
      DEBUG "umount ${1} >/dev/null 2>&1"
      umount ${1} >/dev/null 2>&1
    else
      DEBUG "umount -O bind ${1} >/dev/null 2>&1"
      umount -O bind ${1} >/dev/null 2>&1
    fi
    ATTEMPT=$((ATTEMPT+1))
    [[ $ATTEMPT -ge 3 ]] && printf "failed.\n" && return 3
  done

  if [[ ${1} != none ]]; then
    if [[ ${3} != bind ]]; then
      FSTYPE=$(df -T ${1} | grep ${1} | awk '{print $2}')
      DEBUG "Resulting FSTYPE=${FSTYPE}"
      if [[ ${3} != bind ]]; then
        [[ $FSTYPE != ${3} ]] && printf "wrong file system type\n" && return 1
      fi
    fi
  fi
  printf "done\n"

  return 0
}
# Mount partitions off /mnt/gentoo. These will later be chrooted
# Parameters: None
# Usage:      MountPartitions | tee -a $LOG | ProgressDlg "Mounting partitions" "Please consult Gentoo documentation if there are any errors below:"
function MountPartitions {
  DEBUG "MountPartitions"
  printf "Turning on swap for ${DISK}2...\n"
  grep ${DISK}2 /proc/swaps >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    printf "already swapping\n"
  else
    while : ; do
      printf "mkswap ${DISK}2..."
      DEBUG "mkswap ${DISK}2 2>/dev/null"
      mkswap ${DISK}2 2>/dev/null
      [[ $? -eq 0 ]] && break
      printf "failed.\nTrying again..."
      sleep $SLEEP
    done
    printf "done\n"
    while : ; do
      printf "swapon ${DISK}2\n"
      DEBUG "swapon ${DISK}2 2>/dev/null"
      swapon ${DISK}2 2>/dev/null
      [[ $? -eq 0 ]] && break
      printf "failed.\nTrying again..."
      sleep $SLEEP
    done
    printf "done\n"
  fi
  sleep $SLEEP

  MountPartition /dev/hda1 /mnt/gentoo ext2
  [[ $? -ne 0 ]] && return 1
  MountPartition /dev/hda4 /mnt/gentoo/usr ext3
  [[ $? -ne 0 ]] && return 1
  MountPartition /dev/hda5 /mnt/gentoo/var ext3
  [[ $? -ne 0 ]] && return 1
  MountPartition /dev/hda6 /mnt/gentoo/home ext3
  [[ $? -ne 0 ]] && return 1
  MountPartition none /mnt/gentoo/proc proc
  [[ $? -ne 0 ]] && return 1
# It appears that it is not a good idea to mount /dev since it buggers up /dev/tty1
# which causes problems with DIALOG
# Only mount /dev when running this as a repair CD
  #MountPartition /dev /mnt/gentoo/dev bind
  #[[ $? -ne 0 ]] && return 1
  return 0
}

# Runs a check on the file system
# since we do not know when the last time was this was done.
# We want no funny stuff when we boot up the first time
function _CheckFileSystems {
  DEBUG "CheckFileSystems"
  DEBUG "Checking ${DISK}1...\n"
  DEBUG "fsck -a ${DISK}1"
  fsck -a ${DISK}1 >/dev/null 2>&1
  [[ $? -ne 0 ]] && DIE "There were errors on ${DISK}1.
Restart the installation and choose to rebuild the partitions.
It could also be that your disk is damaged beyond repair."
  DEBUG "Done.\n"
  DEBUG "Checking ${DISK}2...\n"
  DEBUG "fsck -a ${DISK}2"
  fsck -a ${DISK}2 >/dev/null 2>&1
  [[ $? -ne 0 ]] && DIE "There were errors on ${DISK}2.
Restart the installation and choose to rebuild the partitions.
It could also be that your disk is damaged beyond repair."
  DEBUG "Done.\n"
  DEBUG "Checking ${DISK}4...\n"
  DEBUG "fsck -a ${DISK}4"
  fsck -a ${DISK}4 >/dev/null 2>&1
  [[ $? -ne 0 ]] && DIE "There were errors on ${DISK}4.
Restart the installation and choose to rebuild the partitions.
It could also be that your disk is damaged beyond repair."
  DEBUG "Done.\n"
  DEBUG "Checking ${DISK}5...\n"
  DEBUG "fsck -a ${DISK}5"
  fsck -a ${DISK}5 >/dev/null 2>&1
  [[ $? -ne 0 ]] && DIE "There were errors on ${DISK}5.
Restart the installation and choose to rebuild the partitions.
It could also be that your disk is damaged beyond repair."
  DEBUG "Done.\n"
  DEBUG "Checking ${DISK}6...\n"
  DEBUG "fsck -a ${DISK}6"
  fsck -a ${DISK}6 >/dev/null 2>&1
  [[ $? -ne 0 ]] && DIE "There were errors on ${DISK}6.
Restart the installation and choose to rebuild the partitions.
It could also be that your disk is damaged beyond repair."
  DEBUG "Done.\n"
}
function CheckFileSystems {
  $(_CheckFileSystems) | GaugeDlg "Checking file systems" 30
}

#============================================================================#
# INSTALLATION
#============================================================================#

function ShowIntro {
  DEBUG "ShowIntro"
  MessageDlg "Installation of $DISTROTITLE" "Release name: $RELEASE_NAME

This distribution of the GNU Linux kernel and the integrated
set of applications, utilities and services is aimed at
unmodified Sun Ultra 5/10  64-bit computers. Chances are that
it will work on other Sun SPARC boxes too.

Watch the announcements and forums at http://bignoselinux.org.

This distro is based on the Gentoo Linux meta-distro, so
maintenance and configuration is done the Gentoo Linux way
through Gentoo's powerful suite of tools, Portage. Further
details about the Gentoo SPARC distro and Portage is available
here: http://www.gentoo.org"
}

# Installs the tag bzip2 image to /mnt/gentoo
# Does its OWN PROGRESS DIALOG
function InstallImage {
  DEBUG "InstallImage: Begin"
  # Get image name from /mnt/cdrom
  IMAGE=$(ls /mnt/cdrom/snapshots/image*.tar.bz2 | tail -1)
  DEBUG "IMAGE=$IMAGE"
  if [[ -z ${IMAGE} ]]; then
    ErrorDlg "No Install image found in /mnt/cdrom/snapshots" && exit 1 || return 1
  fi
  cd /mnt/gentoo
  # Don't tee to LOG since the log file gets too huge and consumes memory
  tar -xjvpf ${IMAGE} 2>/dev/null | grep "/$" | sed -e 's/\/$//' -e 's/^/\//' | \
    ProgressDlg "Installing ${DISTROTITLE} binary image" "This may take between 5 and 15 minutes..."
  cd -

  DEBUG "Adding missing empty files/dirs in /var"
  [[ ! -d /var/log/apache2 ]] && mkdir /var/log/apache2 2>/dev/null
  touch /var/log/apache2/error_log
  chown -R apache:apache /var/log/apache2
  [[ ! -d /var/log/mysql ]] && mkdir /var/log/mysql 2>/dev/null
  touch /var/log/mysql/mysqld.err
  touch /var/log/mysql/mysql.err
  chown -R mysql:mysql /var/log/mysql
  [[ ! -d /var/run/mysqld ]] && mkdir -p /var/run/mysqld 2>/dev/null
  chown -R mysql:mysql /var/run/mysqld
  [[ ! -d /var/run/fail2ban ]] && mkdir /var/run/fail2ban 2>/dev/null
  touch /var/log/fail2ban.log
  [[ ! -d /var/run/cups ]] && mkdir /var/run/cups 2>/dev/null
  [[ ! -d /var/log/cups ]] && mkdir -p /var/log/cups 2>/dev/null
  [[ ! -d /var/log/gdm ]] && mkdir /var/log/gdm 2>/dev/null
  [[ ! -d /var/log/news ]] && mkdir /var/log/news 2>/dev/null
  [[ ! -d /var/log/partimage ]] && mkdir /var/log/partimage 2>/dev/null
  chown -R partimag:root /var/log/partimage
  [[ ! -d /var/log/sandbox ]] && mkdir -p /var/log/sandbox 2>/dev/null
  chown -R root:portage /var/log/sandbox
  [[ ! -d /var/log/portage ]] && mkdir -p /var/log/portage 2>/dev/null
  [[ ! -d /var/run/dbus ]] && mkdir -p /var/run/dbus 2>/dev/null
  [[ ! -d /var/run/openldap ]] && mkdir /var/run/openldap 2>/dev/null
  [[ ! -d /var/run/distccd ]] && mkdir -p /var/run/distccd 2>/dev/null
  chown -R distcc:daemon /var/run/distccd
  [[ ! -d /var/spool/mqueue ]] && mkdir -p /var/spool/mqueue 2>/dev/null
  [[ ! -d /var/spool/anachron ]] && mkdir -p /var/spool/anachron 2>/dev/null
  [[ ! -d /var/spool/at ]] && mkdir -p /var/spool/at 2>/dev/null
  [[ ! -d /var/spool/mail ]] && mkdir -p /var/spool/mail 2>/dev/null

  DEBUG "InstallImage: Done"
}

#============================================================================#
# NETWORKING
#============================================================================#

# User hostname entry
function GetHostName {
  DEBUG "GetHostName"
  HOSTNAME="bignose"
  NEWHOSTNAME="bignose"
  InputDlg "Host Name" "Enter the hostname for this box.
The default will be '${HOSTNAME}'.
You can leave it like this by hitting 'Cancel':" hostname
  [[ $? -ne 0 ]] && DEBUG "ESCAPE pressed" || DEBUG "OK pressed"

  NEWHOSTNAME=$(cat ${INPUT}.hostname 2>/dev/null)
  NEWHOSTNAME=${NEWHOSTNAME=:-${HOSTNAME}}
  printf $HOSTNAME > ${INPUT}.hostname
  DEBUG "NEWHOSTNAME=$NEWHOSTNAME"
  SetConfigValueEquals ${GENTOO}/etc/conf.d/hostname "HOSTNAME" "$NEWHOSTNAME"
  SetConfigValueTab ${GENTOO}/etc/apache2/httpd.conf "ServerName" "$NEWHOSTNAME"
}

# Get domain name from user
# Write hostname and domainname
function GetDomainName {
  DEBUG "GetDomainName "
  HOSTNAME=$(cat "${INPUT}.hostname" 2>/dev/null)
  HOSTNAME=${HOSTNAME:-bignose}
  DOMAINNAME="ultra"
  NEWDOMAINNAME="ultra"
  InputDlg "Domain Name" "Enter the domain name for this box.

The default will be '${DOMAINNAME}'.
You can leave it like this by hitting 'Cancel'" domainname
  [[ $? -ne 0 ]] && DEBUG "ESCAPE pressed" || DEBUG "OK pressed"
  NEWDOMAINNAME=$(cat ${INPUT}.domainname 2>/dev/null)
  NEWDOMAINNAME=${NEWDOMAINNAME:-"ultra"}
  printf $NEWDOMAINNAME > ${INPUT}.domainname
  DEBUG "NEWDOMAINNAME=$NEWDOMAINNAME"
  rm -f ${GENTOO}/etc/hosts
  SetConfigValueTab ${GENTOO}/etc/hosts "127.0.0.1" "${HOSTNAME}.${NEWDOMAINNAME} ${HOSTNAME} localhost localhost.localdomain"
  echo "::1 localhost" >> ${GENTOO}/etc/hosts
  SetConfigValueEquals ${GENTOO}/etc/conf.d/domainname DNSDOMAIN $NEWDOMAINNAME
}

# Domain searches. By default, the local domain is used.
# A maximum of 6 domains can be set in /etc/resolv.conf
# with a total of 256 chracters
# Returns:  0 success and
#           * Input ignored
function GetDNSSuffix {
  DEBUG "GetDNSSuffix"
  $DIALOG --title "$DNS Search Suffix" --form "Enter all domains that you would like to include
in DNS searches, in the order that they need to be
searched. (max. of 6)

Hit 'Cancel' for none" 0 0 6 \
"1" 1 1 " " 1 3 40 0 \
"2" 2 1 " " 2 3 40 0 \
"3" 3 1 " " 3 3 40 0 \
"4" 4 1 " " 4 3 40 0 \
"5" 5 1 " " 5 3 40 0 \
"6" 6 1 " " 6 3 40 0 \
2>${INPUT}.dnssuffix

  [[ $? -ne 0 ]] && DEBUG "ESCAPE pressed" && return 1
  DEBUG "OK pressed"

  DNSSUFFIXES=$(cat ${INPUT}.dnssuffix | awk '{print $1 $2 $3 $4 $5 $6}')
  if [[ -n $DNSSUFFIXES ]]; then
    # Remove search line
    sed -i -e 's/^search\s.*//' ${GENTOO}/etc/resolv.conf
    # Use echo to prevent conversion of newlines to spaces
    echo search ${DNSSUFFIXES} >> ${GENTOO}/etc/resolv.conf
    DEBUG "DNSSUFFIXES=${DNSSUFFIXES}"
  else
    DEBUG "No DNSSUFFIXES"
  fi
}

# Start of config for setting up the network
# Scan all network interfaces
function ConfigAllNICs {
  DEBUG "ConfigAllNICs"
  # Get network interfaces except for 'lo' and stuff with '_rename'
  NICS=($(ls /sys/class/net | grep -v lo | grep -v _rename))
  [[ -z $NICS ]] && InfoDlg "No network interfaces (NIC's) found!" && return 1
  MACS=($(find /sys/class/net -type f -name "address" -exec grep -v 00:00:00:00:00:00 {} \; ))
  CHECKITEMCOUNT=${#NICS[*]}
  i=0
  CHECKITEMS=""
  # Iterate 2 arrays
  while : ; do
    CHECKITEMS="$CHECKITEMS ${NICS[$i]} ${MACS[$i]} on"
    i=$((i+1))
    [[ $i -ge ${#NICS[*]} ]] && break
  done
  TITLE="Enable/Disable NIC's"
  MSG="Enable or Disable the NIC's below (hit SPACE-bar to toggle)"
  $DIALOG --title "$TITLE" --checklist "$MSG" 10 50 $CHECKITEMCOUNT $CHECKITEMS 2>${INPUT}
  [[ $? -ne 0 ]] && DEBUG "ESCAPE pressed" || DEBUG "OK pressed"
  # look for & Strip speech marks
  ENABLED_NICS=$(grep ^\" ${INPUT} | sed -e 's/"//g')
  aENABLED_NICS=($ENABLED_NICS)
  DEBUG "aENABLED_NICS=${aENABLED_NICS[*]}"

  [[ ${#aENABLED_NICS[*]} -eq 0 ]] && InfoDlg "You have not selected any network interfaces (NIC's). You can
manually configure this afterwards by following the instructions
at http://www.gentoo.org/doc/en/handbook/handbook-sparc.xml" && return 1

  # Now process for each NIC
  for NIC in ${aENABLED_NICS[*]}; do
    # Get operation mode
    SelectNICMode ${NIC}
    case $? in
      0)
        # disable
        break
        ;;
      2)
        # manual
        while : ; do
          GetIPManualConfig ${NIC}
          [[ $? -eq 0 ]] && break
        done
        ;;
      *)
        # DHCP chosen
        ;;
    esac
    # Get device details
    GetNICDeviceDetails ${NIC}
    WriteWiredConfig ${NIC}
  done
}

# PRIVATE
# User chooses DHCP or manual config for a NIC
# Parameters: NIC identifier,i.e. eth0, wlan0,...
# Returns:    0 Disabled
#             1 DHCP
#             2 MANUAL
function SelectNICMode {
  DEBUG "SelectNICMode ${*}"
  NIC=${1}
  ${DIALOG} --title "Type of Network setup for ${NIC}" --radiolist "Choose the type of network setup that you want to
use for network interface '${NIC}'

(Hit SPACE-bar to select)" 12 55 2 1 "DHCP IP address assignment" on 2 "Manual IP address configuration" off 2>${INPUT}
  CHOICE=$(grep ^[12] ${INPUT}) # Do this to deal with a problem with /usr/bin/dialog
  CHOICE=${CHOICE:-0}
  LOOKUP=(disable dhcp manual)
  DEBUG "User chose $CHOICE -> ${LOOKUP[$CHOICE]}"
  SetConfigValueEquals "${INPUT}.${NIC}" mode ${LOOKUP[$CHOICE]}
  return $CHOICE
}

# PRIVATE
# Get specs for NIC
# Parmaeters: NIC, i.e. eth0, wlan0 etc...
# Prints:    "BUS MAC DRIVER DEVNAME"
# Code:       0 if success
#             1 if failed
function GetNICDeviceDetails {
  DEBUG "GetNICDeviceDetails ${*}"
  NIC=$1
  [[ -z ${NIC} ]] && printf "You need to specify a NIC.\n" && return 1
  MAC=$(cat /sys/class/net/${NIC}/address)

  BUS=$(basename `readlink /sys/class/net/${NIC}/device/bus`)
  case "${BUS}" in
    'pci' )
      PCIADDRESS=$(basename `readlink /sys/class/net/${NIC}/device`)
      DEVNAME=$(lspci -s $PCIADDRESS)
      DEVNAME="${DEVNAME#*: }"
      DEVNAME="${DEVNAME%(rev *)}"
      ;;
    'usb' )
      USBPATH="/sys/class/net/${iface}/$(dirname $(readlink /sys/class/net/${NIC}/device))"
      MANUFACTURER="$(< ${USBPATH}/manufacturer)"
      USBPRODUCT"$(< ${USBPATH}/product)"
      [[ -n ${MANUFACTURER} ]] && DEVNAME="${MANUFACTURER}"
      [[ -n ${USBPRODUCT} ]] && DEVNAME="${DEVNAME}${USBPRODUCT}"
      ;;
    'ieee1394' )
      DEVNAME="IEEE1394 (FireWire) Network Adapter"
      ;;
    * )
      :
      ;;
  esac

  DRIVER=$(basename `readlink /sys/class/net/${NIC}/device/driver`)
  [[ -z $DEVNAME ]] && $DEVNAME=$DRIVER
  [[ -z $DEVNAME ]] && $DEVNAME=$MAC
  SetConfigValueEquals ${INPUT}.${NIC} bus "$BUS"
  SetConfigValueEquals ${INPUT}.${NIC} mac "$MAC"
  SetConfigValueEquals ${INPUT}.${NIC} driver "$DRIVER"
  SetConfigValueEquals ${INPUT}.${NIC} devname "$DEVNAME"
  return 0
}

# Gets Non-DHCP IP configuration
# Parameters: NIC
# Optional:   IPAddress NetMask Gateway Broadcast DNSService1 DNSService2
# Outputs:    IPAddress NetMask Gateway Broadcast DNSService1 DNSService2
# Return 0 if sucessfull
#        1 if failed
function GetIPManualConfig {
  DEBUG "GetIPManualConfig $1"
  NIC="$1"
  [[ -z $NIC ]] && printf "You need to specify a NIC.\n" && return 1

  # Get existing values if any
  DNSService1=$(grep dnsservice1 ${INPUT}.${NIC} | sed -e 's/..*=//' -e 's/"//g')
  DNSService1=${DNSService1:-"192.168.0.250"}
  DNSService2=$(grep dnsservice2 ${INPUT}.${NIC} | sed -e 's/..*=//' -e 's/"//g')
  DNSService2=${DNSService2:-"192.168.0.251"}

  # Set default values
  [[ -z $2 ]] && aIPAddress=($(echo "192.168.0.66"  | sed -e 's/\./ /g')) || aIPAddress=($(echo $2   | sed -e 's/\./ /g'))
  [[ -z $3 ]] && aNetMask=($(echo "255.255.255.0"   | sed -e 's/\./ /g')) || aNetMask=($(echo $3     | sed -e 's/\./ /g'))
  [[ -z $4 ]] && aGateway=($(echo "192.168.0.250"   | sed -e 's/\./ /g')) || aGateway=($(echo $4     | sed -e 's/\./ /g'))
  [[ -z $5 ]] && aBroadcast=($(echo "192.168.0.255" | sed -e 's/\./ /g')) || aBroadcast=($(echo $5   | sed -e 's/\./ /g'))
  [[ -z $6 ]] && aDNSService1=($(echo $DNSService1  | sed -e 's/\./ /g')) || aDNSService1=($(echo $6 | sed -e 's/\./ /g'))
  [[ -z $7 ]] && aDNSService2=($(echo $DNSService2  | sed -e 's/\./ /g')) || aDNSService1=($(echo $7 | sed -e 's/\./ /g'))

  TITLE="Manual IP Configuration for ${NIC}"
  $DIALOG --title "$TITLE" --form "Use Arrow keys to select fields:" 0 0 6 \
"IP Address:" 1 1  "${aIPAddress[0]}" 1 13 4 3 "." 1 17 "${aIPAddress[1]}" 1 18 4 3 \
          "." 1 22 "${aIPAddress[2]}" 1 23 4 3 "." 1 27 "${aIPAddress[3]}" 1 28 4 3 \
"Net Mask:  " 2 1  "${aNetMask[0]}" 2 13 4 3 "." 2 17 "${aNetMask[1]}" 2 18 4 3 \
          "." 2 22 "${aNetMask[2]}" 2 23 4 3 "." 2 27 "${aNetMask[3]}" 2 28 4 3 \
"Gateway:   " 3 1  "${aGateway[0]}" 3 13 4 3 "." 3 17 "${aGateway[1]}" 3 18 4 3 \
          "." 3 22 "${aGateway[2]}" 3 23 4 3 "." 3 27 "${aGateway[3]}" 3 28 4 3 \
"Broadcast: " 4 1  "${aBroadcast[0]}" 4 13 4 3 "." 4 17 "${aBroadcast[1]}" 4 18 4 3 \
          "." 4 22 "${aBroadcast[2]}" 4 23 4 3 "." 4 27 "${aBroadcast[3]}" 4 28 4 3 \
"Nameserver:" 5 1  "${aDNSService1[0]}" 5 13 4 3 "." 5 17 "${aDNSService1[1]}" 5 18 4 3 \
          "." 5 22 "${aDNSService1[2]}" 5 23 4 3 "." 5 27 "${aDNSService1[3]}" 5 28 4 3 \
"Nameserver:" 6 1  "${aDNSService2[0]}" 6 13 4 3 "." 6 17 "${aDNSService2[1]}" 6 18 4 3 \
          "." 6 22 "${aDNSService2[2]}" 6 23 4 3 "." 6 27 "${aDNSService2[3]}" 6 28 4 3 \
2>$INPUT

  declare -i a
  a=($(cat $INPUT))
  # Check values
  i=0
  while : ; do
    if [[ ${a[$i]} -gt 255 ]]; then
      ErrorDlg "Invalid IP-address value of '${a[$i]}' in field $((i+1)). Please try again...\\n\\n"
      return 1
    fi
    i=$((i+1))
    [[ $i -ge 24 ]] && break
  done

  IPAddress=${a[0]:-0}.${a[1]:-0}.${a[2]:-0}.${a[3]:-0}
  NetMask=${a[4]:-0}.${a[5]:-0}.${a[6]:-0}.${a[7]:-0}
  Gateway=${a[8]:-0}.${a[9]:-0}.${a[10]:-0}.${a[11]:-0}
  Broadcast=${a[12]:-0}.${a[13]:-0}.${a[14]:-0}.${a[15]:-0}
  DNSService1=${a[16]:-0}.${a[17]:-0}.${a[18]:-0}.${a[19]:-0}
  DNSService2=${a[20]:-0}.${a[21]:-0}.${a[22]:-0}.${a[23]:-0}

  SetConfigValueEquals ${INPUT}.${NIC} ipaddress $IPAddress
  SetConfigValueEquals ${INPUT}.${NIC} netmask $NetMask
  SetConfigValueEquals ${INPUT}.${NIC} gateway $Gateway
  SetConfigValueEquals ${INPUT}.${NIC} broadcast $Broadcast
  SetConfigValueEquals ${INPUT}.${NIC} dnsservice1 $DNSService1
  SetConfigValueEquals ${INPUT}.${NIC} dnsservice2 $DNSService2
  SetConfigValueEquals ${INPUT}.nameserver dnsservice1 $DNSService1
  SetConfigValueEquals ${INPUT}.nameserver dnsservice2 $DNSService2
  return 0
}

# Get WiFi Configuration for a WiFi NIC
# Also calls `iwconfig` to set values. This is not part of the Gentoo LiveDisk
# Parameters: NIC
# Returns:    SSIS WEP(1/2) WEPTYPE WEPKEY
function GetWiFiConfig {
  DEBUG "GetWiFiConfig $*"
  NIC=$1
  [ -x /usr/sbin/iwconfig ] && iwconfig=/usr/sbin/iwconfig
  [ -x /sbin/iwconfig ] && iwconfig=/sbin/iwconfig
  [ -z ${iwconfig} ] &&  ErrorDlg "iwconfig not found" && exit 1
  TITLE="SSID for ${NIC}"
  MSG="Please enter your WiFi card's SSID or leave blank for selecting the nearest open network"
  InputDlg "$TITLE" "$MSG" ssid
  SSID=$(cat ${INPUT}.ssid)
  if [ -n ${SSID} ]; then
    TITLE="WEP encryption for ${NIC}"
    MSG="Does your network use encryption?"
    $DIALOG --title "$TITLE" --menu "$MSG" 20 60 7 1 "Yes" 2 "No" 2> ${INPUT}
    WEP=$(cat ${INPUT})
    case ${WEP} in
      1)
        TITLE="WEP key for ${NIC}"
        MSG="Are you entering your WEP key in HEX or ASCII?"
        $DIALOG --title "$TITLE" --menu "$MSG" 20 60 7 1 "HEX" 2 "ASCII" 2> ${INPUT}
        WEPTYPE=$(cat ${INPUT})
        case ${WEPTYPE} in
          1)
            TITLE="HEX WEP key for ${NIC}"
            MSG="Please enter your WEP key in the form of XXXX-XXXX-XX for 64-bit or XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XX for 128-bit"
            InputDlg "$TITLE" "$MSG" webkey
            WEP_KEY=$(cat ${INPUT}.webkey)
            if [ -n "${WEP_KEY}" ]; then
              ${iwconfig} ${NIC} essid "${SSID}"
              ${iwconfig} ${NIC} key "${WEP_KEY}"
            fi
          ;;
          2)
            TITLE="ASCII WEP key for ${NIC}"
            MSG="Please enter your WEP key in ASCII form. This should be 5 or 13 characters for either 64-bit or 128-bit encryption, repectively"
            InputDlg "$TITLE" "$MSG" webkey
            WEP_KEY=$(cat ${INPUT}.webkey)
            if [ -n "${WEP_KEY}" ]; then
              ${iwconfig} ${NIC} essid "${SSID}"
              ${iwconfig} ${NIC} key "s:${WEP_KEY}"
            fi
          ;;
        esac
      ;;
      2)
        ${iwconfig} ${NIC} essid "${SSID}"
        ${iwconfig} ${NIC} key off
      ;;
    esac
  fi
  printf "$SSIS $WEP $WEPTYPE $WEPKEY\n"
  return 0
}

# Write configuration for WiFi NIC
# Parameters: NIC, SSID, WEP(1/2) WEPTYPE(1/2), WEPKEY
# Use /etc/conf.d/net instead of /etc/conf.d/wireless
function WriteWiFiConfig {
  DEBUG "WriteWiFiConfig $*"
  NIC=$1
  SSID=$2
  if [ -n "${SSID}" ]; then
    printf "# Added on $(date +%Y.%m.%d):\n" >> /etc/conf.d/net
    WEP=$3
    if [ $WEP -eq 1 ]; then
      WEPTYPE=$4
      WEPKEY=$5
      case ${WEPTYPE} in
        1)
          if [ -n "${WEP_KEY}" ]; then
            SSID_TRANS="$(echo ${SSID//[![:word:]]/_})"
            case ${WEPTYPE} in
              1)
                printf "key_${SSID_TRANS}=\"${WEP_KEY} enc open\"\n" >> /etc/conf.d/net
                ;;
              2)
                printf "key_${SSID_TRANS}=\"s:${WEP_KEY} enc open\"\n" >> /etc/conf.d/net
                ;;
            esac
          fi
          ;;
        2)
          :
          ;;
      esac
    fi
    printf "preferred_aps=( \"${SSID}\" )\n" >> /etc/conf.d/net
    printf "associate_order=\"forcepreferredonly\"\n" >> /etc/conf.d/net
  fi
}

# Write configuration to mounted environment for a wired NIC's
# Parameters: NIC DHCP(1/2) LOCALDOMAIN IPADDRESS NETMASK GATEWAY BROADCAST
function WriteWiredConfig {
  NIC=$1
  DEBUG "WriteWiredConfig $NIC"
  MODE=$(GetConfigValueEquals ${INPUT}.${NIC} mode)
  case ${MODE} in
    dhcp )
      SetConfigValueEquals ${GENTOO}/etc/conf.d/net config_${NIC} "(\"dhcp\")"
      ;;
    manual )
      IPADDRESS=$(grep ipaddress ${INPUT}.${NIC} | sed -e 's/..*=//' -e 's/"//g')
      NETMASK=$(grep netmask ${INPUT}.${NIC} | sed -e 's/..*=//' -e 's/"//g')
      GATEWAY=$(grep gateway ${INPUT}.${NIC} | sed -e 's/..*=//' -e 's/"//g')
      BROADCAST=$(grep broadcast ${INPUT}.${NIC} | sed -e 's/..*=//' -e 's/"//g')
      if [ -n "${IPADDRESS}" -a -n "${BROADCAST}" -a -n "${NETMASK}" ]; then
        SetConfigValueEquals ${GENTOO}/etc/conf.d/net config_${NIC} "(\"${IPADDRESS} broadcast ${BROADCAST} netmask ${NETMASK}\")"
        if [ -n "${GATEWAY}" ]; then
          SetConfigValueEquals ${GENTOO}/etc/conf.d/net gateway \"${NIC}/${GATEWAY}\"
          SetConfigValueEquals ${GENTOO}/etc/conf.d/net routes_${NIC} "( \"default via ${GATEWAY}\" )"
          # /sbin/route add default gw ${GATEWAY} dev ${NIC} netmask 0.0.0.0 metric 1
        fi
      fi
      ;;
    *)
      ErrorDlg "Unusual DHCP option in WriteWiredConfig.\\n\\nOperational mode=$MODE."
      ;;
  esac
}

# Write nameserver and domain config
# Values are obtained from ${INPUT}.nameserver
function WriteNameserverConfig {
  DEBUG "WriteNameserverConfig"
  # Write local domain whether DHCP or FIXED:
  DOMAINNAME=$(cat ${INPUT}.domainname)
  if [[ -n ${DOMAINNAME} ]]; then
    SetConfigValueEquals ${GENTOO}/etc/conf.d/net dns_domain_lo "dns.${DOMAINNAME}"
    SetConfigValueEquals ${GENTOO}/etc/conf.d/net nis_domain_lo "nis.${DOMAINNAME}"
    SetConfigValueTab ${GENTOO}/etc/resolv.conf domain ${DOMAINNAME}
  fi

  # Write nameservice whether DHCP or FIXED:
  DNSService1=$(grep dnsservice1 ${INPUT}.nameserver | sed -e 's/..*=//' -e 's/"//g')
  [[ -n $DNSService1 ]] && \
    SetConfigValueTab ${GENTOO}/etc/resolv.conf nameserver "${DNSService1}"
  DNSService2=$(grep dnsservice2 ${INPUT}.nameserver | sed -e 's/..*=//' -e 's/"//g')
  [[ -n $DNSService2 ]] && \
    SetConfigValueTab ${GENTOO}/etc/resolv.conf nameserver "${DNSService2}"
}

# Prompts for password for a user and then sets it using the UNIX `passwd` command
# If a week password is entered, the user can re-enter the passwords.
#
# Security Note: While the password is passed via the `expect` utility
# to the `passwd` utility, it is in clear text and is available for the
# duration of the call, albeit for a very short time.
# This sort of thing was OK in the old days but now we know better, right?
# Except that this installation is reasonably secure and nobody other
# than yourself could possibly be using it right now.
# Your only real security risk is one of someone shoulder-surfing.
# Parameters: UNIX user name. Defaults to 'root'
# Returns:  0 Success
#           1 Failed
#function GetSetPassword {
#  USERNAME=$1
#  USERNAME=${USERNAME:-root}
#  DEBUG "GetSetPassword for $USERNAME"
#  while : ; do
#    $DIALOG --title "Get ${USERNAME} password" --insecure --passwordbox "Enter ${USERNAME} password" 8 55 2>$PASSWD
#    pw1=$(cat $PASSWD) ; rm -f $PASSWD
#    $DIALOG --title "Confirm ${USERNAME} password" --insecure --passwordbox "Enter ${USERNAME} password again" 8 55 2>$PASSWD
#    pw2=$(cat $PASSWD) ; rm -f $PASSWD
#    [[ "${pw1}" = "${pw2}" ]] && break
#    YesNoDlg "Password Mismatch" "The two passwords that you entered don't match.
#Do you want to enter them again?
#
#('No' exits the installation)"
#    [[ $? -ne 0 ]] && retun 1
#  done
#
#  # Set passwd
#  #expect -d -  1>>${LOG} 2>/dev/null <<-!
#  #expect 1>/dev/null 2>&1 <<-!
#  expect 1>>${LOG} 2>&1 <<-!
#  spawn "/bin/bash"
#  send "passwd $USERNAME\r\n"
#  sleep 0.5
#  expect -re "assword: "
#  send "$pw1\r\n"
#  sleep 0.5
#  # Another entry in case of weak password:
#  expect -re "assword: "
#  send "$pw1\r\n"
#  sleep 0.5
#  expect -re "successfully"
#!
#
#  return 0
#}
# Bollocks to this! Error:
# The system has no more ptys.  Ask your system administrator to create more.
# Need to rebuild host kernel.
# CONFIG_UNIX98_PTYS=y
# CONFIG_DEVPTS_FS=y
# Can I find the .config file? No. So we go a la console screen!
function GetSetPassword {
  USERNAME=$1
  USERNAME=${USERNAME:-root}
  DEBUG "GetSetPassword for $USERNAME"
  passwd ${USERNAME} 2>>${LOG}
  return $?
}

# End of installation of successfull
# Returns:  0 User wants to reboot
function Goodbye {
  DEBUG "Goodbye"
  HOSTNAME=$(cat ${INPUT}.hostname)
  YesNoDlg "End of installation" "
The installation of $DISTROTITLE
on your Sun box appears to have been successfull,
but before we reboot to the hard drive, you should
note the following:

If the box does not boot to hard disk, go into the
OpenProm (the 'ok' prompt -- hit Stop-A or Stop-L1)
and type:

   ok boot disk

Refer to the OpenProm documentation on how to set
the hard disk as the first boot device.

Assuming that the network card has been correctly
configured, you should, after a successfull reboot,
be able to remotely connect from another terminal to
this machine using the operator account that you
entered earlier on in the installation, as follows:

  $ ssh operator@${HOSTNAME}
  Password: <enter operator's password>

Only then can you login to the root account to make
system changes:

  operator@${HOSTNAME} / $ su -
  Password: <enter root's password>

Do you want to reboot the computer now?"
  return $?
}

# Sets the boot block to point to the /boot/silo.conf file
# (which must be on the same physical hard disk!)
# This must be called from the chroot'ed environment
function _InstallSILO {
  DEBUG "_InstallSILO:"
  printf "Check if silo checker is installed..."
  SILO=$(which silo)
  [[ $? -ne 0 ]] && ErrorDlg "silo is not installed." && exit 1
  printf "found $SILO\n"

  printf "Check silo.conf file..."
  $SILO -f -C /boot/silo.conf
  [[ $? -eq 1 ]] && ErrorDlg "silo.conf is invalid." && exit 1
  sleep $SLEEP
}
function InstallSILO {
  DEBUG "InstallSILO:"
  _InstallSILO | ProgressDlg "Setting Bootloader" "Use the SILO bootloader"
}

# CHROOT'ed function
# Create SSH key-pairs
function _CreateSSHKeyPairs {
  rm /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_key /etc/ssh/ssh_host_key.pub /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key.pub
  /etc/init.d/sshd --nocolor start
}
function CreateSSHKeyPairs {
  DEBUG "CreateSSHKeyPairs:"
  _CreateSSHKeyPairs | ProgressDlg "Creating SSH Keypairs" "DSA and RSA keys"
  sleep $SLEEP
}

# Run programs to seed the system
# for a smooth first-time start
function _FinishOffInstallation {
  DEBUG "_FinishOffInstallation"
  printf "Seed Webalizer...\n"
  rm /var/www/localhost/htdocs/webalizer/*
  touch /var/www/localhost/htdocs/webalizer/webalizer.hist
  /usr/bin/webalizer 2>&1
  printf "Done.\n"
}
function FinishOffInstallation {
  DEBUG "FinishOffInstallation:"
  _FinishOffInstallation | ProgressDlg "Run a few programs once to seed the system"
}

# Gets operator account's email address for notifications
function GetSysAdminEmail {
  DEBUG "GetSysAdminEmail"
  InputDlg "SysAdmin Notification Email Address" "Enter the email address of the person who should be notified
of system events:

(Hit 'Cancel' if you do not want to send such notifications)" opsemail
  RETCODE=$?
  [[ $RETCODE -ne 0 ]] && DEBUG "ESCAPE pressed" || DEBUG "OK pressed"
  if [[ $RETCODE -eq 0 ]]; then
    OPSEMAIL=$(cat ${INPUT}.opsemail 2>/dev/null)
    if [[ -n $OPSEMAIL ]]; then
      DEBUG "OPSEMAIL=$OPSEMAIL"
      SetConfigValueTab "/mnt/gentoo/etc/mail/aliases" "root:" $OPSEMAIL
      SetConfigValueTab "/mnt/gentoo/etc/mail/aliases" "operator:" $OPSEMAIL
    else
      DEBUG "No SysAdmin email was entered"
      return 1
    fi
  else
    return 1
  fi
}

#  Choose to start with X-windows login screen
function SelectXWindows {
  DEBUG "SelectXWindows"
  YesNoDlg "X-Windows Configuration" "Do you want X-Windows to automatically start on boot-up?

Note:
You can manually start X-Windows with the command:
  # startx

"
  if [[ $? -eq 0 ]]; then
    # 'Yes':
    ln -s ${GENTOO}/etc/init.d/slim ${GENTOO}/etc/runlevels/default/slim
  else
    # 'No':
    # Disable it as the development environment had it enabled by default
    rm -f ${GENTOO}/etc/runlevels/default/slim 2>/dev/null
  fi
}

# The user can choose to start the SSH service on startup or not
function ConfigureSSH {
  DEBUG "ConfigureSSH"
  YesNoDlg "SSH  Service Configuration" "Do you want the SSH service to automatically start on boot-up?

Notes:
You can manually start the SSH service with the command:
  # /etc/init.d/sshd start

"
  if [[ $? -eq 0 ]]; then
    # 'Yes':
    ln -s ${GENTOO}/etc/init.d/sshd ${GENTOO}/etc/runlevels/default/sshd
  else
    # 'No':
    # Disable it as the development environment had it enabled by default
    rm -f ${GENTOO}/etc/runlevels/default/sshd 2>/dev/null
  fi
}

# Add more users
function _AddMoreUsers {
  DEBUG "AddMoreUsers"

  TITLE="Enter Account User Details"
  $DIALOG --title "$TITLE" --form "Use Arrow keys to select fields:" 0 0 6 \
"Login:"     1 1 "" 1 14 20 21 \
"Full name:" 3 1 "" 3 14 20 21 \
  2>$INPUT
  [[ $? -ne 0 ]] && return 1
  # Process input
  a=($(cat $INPUT))
  USERNAME=${a[0]}
  COMMENT="${a[1]} ${a[2]} ${a[3]}"
  DEBUG "chroot ${GENTOO} useradd -m -G users,sshd,audio,video,cdrom,usb,wheel ${USERNAME}"
  #chroot ${GENTOO} useradd -m -G users,sshd,audio,video,cdrom,usb,wheel -s /bin/bash -c \"${COMMENT}\" $USERNAME 2>/dev/null
  chroot ${GENTOO} useradd -m -G users,sshd,audio,video,cdrom,usb,wheel ${USERNAME} >> ${LOG} 2>&1
  DEBUG "chroot ${GENTOO} usermod -c \"${COMMENT}\" ${USERNAME}"
  chroot ${GENTOO} usermod -c "${COMMENT}" ${USERNAME} >> ${LOG} 2>&1
  if [[ $? -ne 0 ]]; then
    WarningDlg "User ${a[0]} already exists."
    return 1
  fi

  DEBUG "Set up XWindows config for user ${a[0]}"
  cp -r "${GENTOO}/root/.fluxbox"  "${GENTOO}/home/${a[0]}/."
  cp -r "${GENTOO}/root/.idesktop" "${GENTOO}/home/${a[0]}/."
  cp -r "${GENTOO}/root/.ideskrc" "${GENTOO}/home/${a[0]}/."
  DEBUG "chown -R --reference=${GENTOO}/home/${USERNAME} ${GENTOO}/home/${USERNAME}/.*"
  chown -R --reference=${GENTOO}/home/${USERNAME} ${GENTOO}/home/${USERNAME}/.* >> ${LOG} 2>&1
  DEBUG "chown -R --reference=${GENTOO}/home/${USERNAME} ${GENTOO}/home/${USERNAME}/*"
  chown -R --reference=${GENTOO}/home/${USERNAME} ${GENTOO}/home/${USERNAME}/* >> ${LOG} 2>&1

  # Set user password
  #chroot ${GENTOO} /tmp/${THIS} GetSetPassword ${USERNAME}
  FlashDlg "Password Setup" "Enter the password for user ${USERNAME}:"
  chroot ${GENTOO} passwd ${USERNAME} #2>>${LOG}
  if [[ $? -ne 0 ]]; then
    WarningDlg "Failed to set the password for user ${USERNAME}.

Note:
You can set the password later with the command:
  # password ${USERNAME}

"
    return 0
  fi
}
function AddMoreUsers {
  DEBUG "AddMoreUsers"

  while : ; do
    NUMNEWUSERS=$(cut -f 3 -d : ${GENTOO}/etc/passwd | awk '{if ($1 >= 1000) print $1}' | wc -l | awk '{print $1-1}')
    case ${NUMNEWUSERS} in
      0 )
        MSG="There are not any user accounts yet.
Do you want to create a user account now?


Note:
You can add some later with the command:
  # useradd -m -G users,sshd,audio,video,cdrom,usb,wheel [UserLogin]

"
        ;;
      1 )
        MSG="So far there is only one user account.\nDo you want to create another user account?"
        ;;
      * )
        MSG="There are ${NUMNEWUSERS} user accounts so far. Do you want to create another user account?"
        ;;
    esac
    YesNoDlg "User Account" "${MSG}"
    [[ $? -ne 0 ]] && break
    _AddMoreUsers
  done
}


##############################################################################
# Step 0.  Show introduction                                                 #
##############################################################################
function Step0 {
  DEBUG "Step0"
  STATUS="INTRODUCTION"
  ShowIntro
}

##############################################################################
# Step 1.  Check feasibility of installing to the target computer            #
##############################################################################
function Step1 {
  DEBUG "Step1"
  STATUS="STEP 1: Hardware check"
  ShowComputerSpecs
  }

##############################################################################
# Step 2.  Partition disk                                                    #
##############################################################################
function Step2 {
  DEBUG "Step2"
  STATUS="Step 2: Partition Disk"
  # Do this for good measure:
  UnmountPartitions  1>/dev/null 2>&1
  [[ $? -ne 0 ]] && DIE "Failed to unmount all partitions on ${DISK}"

  CheckExistingDiskPartition
  case $? in
    0 )
      # Create partitions
      CalcPartitionSizes 2>$INPUT
      SIZES=$(cat $INPUT)
      CreateSUNDiskLabel 2>&1 | tee -a $LOG | ProgressDlg "Creating SUN disk label" "Please wait and let the process finish..."
      CreateAllPartitions $SIZES 2>&1 | tee -a $LOG | ProgressDlg "Creating disk partitions" "This may take a while..."
      :
      ;;
    1 )
      # User chose to (re-)partition disk
      RemoveAllDiskPartitions 2>&1 | tee -a $LOG | ProgressDlg "Removing existing disk partitions" "Please wait..."
      RemoveWholeDiskPartition
      CalcPartitionSizes 2>$INPUT
      SIZES=$(cat $INPUT)
      CreateSUNDiskLabel 2>&1 | tee -a $LOG | ProgressDlg "Creating SUN Disk Label" "Please wait..."
      CreateAllPartitions $SIZES 2>&1 | tee -a $LOG | ProgressDlg "Creating disk partitions" "This may take a while..."
      ;;
    2 )
      # User chose to keep existing partitions
      # The mounting process will ensure that the disk was partitioned correctly.
      :
      ;;
    * )
      :
      ;;
  esac

  CheckFileSystems
}

##############################################################################
# Step 3.  Mount partitions                                                  #
##############################################################################
function Step3 {
  DEBUG "Step3"
  STATUS="Step 3: Mount partitions"
  MountPartitions | ProgressDlg "Mounting Partitions"
  ShowPartitionSizes
}

##############################################################################
# Step 4.  Copy installation images to mount points                          #
##############################################################################
function Step4 {
  DEBUG "Step4"
  STATUS="Step 4: Install Image"
  InstallImage
}
##############################################################################
# Step 5.  Configure environment configuration                               #
##############################################################################
function Step5 {
  DEBUG "Step5"
  STATUS="Step 5: Configure Server"
  GetHostName
  GetDomainName
  GetDNSSuffix
  ConfigAllNICs
  WriteNameserverConfig
}
##############################################################################
# Step 6.  Configure users                                                   #
##############################################################################
function Step6 {
  DEBUG "Step6"
  STATUS="Step 6: Set up Users"
  # Prepare for chrooting:
  # Copy this script to the installed image's /tmp dir
  # The cp command on the livecd is a bit weird...
  rm -fr /mnt/gentoo/tmp/${THIS} 1>/dev/null 2>&1
  cp $0 /mnt/gentoo/tmp/. 1>/dev/null 2>&1
  EXITMESSAGE=""
  #chroot ${GENTOO} /tmp/${THIS} GetSetPassword
  FlashDlg "Password Setup" "Enter the password for user 'root':"
  chroot ${GENTOO} passwd root #2>>${LOG}
  [[ $? -ne 0 ]] && exit 1
  #chroot ${GENTOO} /tmp/${THIS} GetSetPassword operator
  FlashDlg "Password Setup" "Enter the password for user 'operator':"

  chroot ${GENTOO} passwd operator #2>>${LOG}
  [[ $? -ne 0 ]] && exit 1
  GetSysAdminEmail
  AddMoreUsers
}
##############################################################################
# Step 7.  Configure services                                                #
##############################################################################
function Step7 {
  DEBUG "Step7"
  STATUS="Step 7: Configure Serives"
  # Prepare again for chrooting:
  # Copy this script to the installed image's /tmp dir
  # The cp command on the livecd is a bit weird...
  rm -fr /mnt/gentoo/tmp/${THIS} 1>/dev/null 2>&1
  cp $0 /mnt/gentoo/tmp/. 1>/dev/null 2>&1
  EXITMESSAGE=""
  chroot /mnt/gentoo /tmp/${THIS} SelectXWindows
  #chroot /mnt/gentoo /tmp/${THIS} CreateSSHKeyPairs
  chroot /mnt/gentoo /tmp/${THIS} ConfigureSSH
}
##############################################################################
# Step 8. Finish off installation                                            #
##############################################################################
function Step8 {
  DEBUG "Step8"
  STATUS="Step 8: Finishing off the installation"
  # Prepare for chrooting:
  # Copy this script to the installed image's /tmp dir
  # The cp command on the livecd is a bit weird...
  rm -fr /mnt/gentoo/tmp/${THIS} 1>/dev/null 2>&1
  cp $0 /mnt/gentoo/tmp/. 1>/dev/null 2>&1
  EXITMESSAGE=""
  chroot /mnt/gentoo /tmp/${THIS} InstallSILO
  [[ $? -ne 0 ]] && exit 1
  chroot /mnt/gentoo /tmp/${THIS} FinishOffInstallation
}
##############################################################################
# Step 9.  Reboot                                                            #
##############################################################################
function Step9 {
  DEBUG "Step9"
  STATUS="Step 9: Reboot"
  # Clean up installation debris
  rm -fr /mnt/gentoo/tmp/* 1>/dev/null 2>&1

  ShowDiskUsage
  EXITMESSAGE="Rebooting..."
  Goodbye
  if [[ $? -ne 0 ]]; then
    MessageDlg "Installation complete" "
You will now be chroot'ed to the new installed
environment. Type exit when you are ready to
reboot your BigNose box.

Press 'OK' to continue...
"
    # Prepare for chrooting:
    # Copy this script to the installed image's /tmp dir
    # The cp command on the livecd is a bit weird...
    rm -fr /mnt/gentoo/tmp/${THIS} 1>/dev/null 2>&1
    cp $0 /mnt/gentoo/tmp/. 1>/dev/null 2>&1
    EXITMESSAGE=""

    chroot /mnt/gentoo /bin/bash
    # do stuff...and then type exit
  fi
  InfoDlg "The computer will now shut down and attempt to\nreboot off hard disk ${DISK}. "
  UnmountPartitions 2>&1 | ProgressDlg "Unmounting partitions on ${DISK}"
  reboot &

  DEBUG "End of installation"
  DEBUG "##############################################################################"
}

##############################################################################
# MAIN
##############################################################################
function main {
  DEBUG "##############################################################################"
  DEBUG "main"
  #rm -fr $LOG
  EXITMESSAGE="Installation stopped"

  Step0
  Step1
  Step2
  Step3
  Step4
  Step5
  Step6
  Step7
  Step8
  Step9
}

##############################################################################
# Parse input parameters:
# ~~~~~~~~~~~~~~~~~~~~~~
# Parameters: Function name
#             If not parameters then call DoInstall
FUNCTION="${1}"
[[ -z $FUNCTION ]] && FUNCTION="main"
# Pass all parameters except for the function name
shift
${FUNCTION} ${*}
RETCODE=$?
# Can only return a value if called as a function
#return ${RETCODE}