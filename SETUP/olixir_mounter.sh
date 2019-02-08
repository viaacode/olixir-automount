#!/bin/bash

# This script is called from our UDEV rule

usage()
{
    echo "Usage: $0 {add|remove} device_name (e.g. /dev/sdb1)"
    exit 1
}

if [[ $# -ne 2 ]]; then
    usage
fi


ACTION="$1"
DEVBASE="$2"
DEVICE="${DEVBASE}"
APIIP="0.0.0.0"

### Logic to get the bay number

if [[ $ID_PATH == "pci-0000:01:00.0-scsi-0:0:14:0" ]]; then
	BAY=2
	echo $BAY is used for mounting $DEVICE >> /tmp/testudev.log
elif [[ $ID_PATH == "pci-0000:01:00.0-scsi-0:0:13:0" ]]; then
        BAY=1
        echo $BAY is used for mounting $DEVICE >> /tmp/testudev.log
elif [[ $ID_PATH == "pci-0000:01:00.0-scsi-0:0:15:0" ]]; then
        BAY=3
        echo $BAY is used for mounting $DEVICE >> /tmp/testudev.log
elif [[ $ID_PATH == "pci-0000:01:00.0-scsi-0:0:12:0" ]]; then
        BAY=4
        echo $BAY is used for mounting $DEVICE >> /tmp/testudev.log
elif [[ $ID_PATH == "pci-0000:01:00.0-scsi-0:0:11:0" ]]; then
        BAY=5
        echo $BAY is used for mounting $DEVICE >> /tmp/testudev.log

elif [[ $ID_PATH == "pci-0000:01:00.0-scsi-0:0:10:0" ]]; then
        BAY=6
        echo $BAY is used for mounting $DEVICE >> /tmp/testudev.log
elif [[ $ID_PATH == "pci-0000:01:00.0-scsi-0:0:9:0" ]]; then
        BAY=7
        echo $BAY is used for mounting $DEVICE >> /tmp/testudev.log
elif [[ $ID_PATH == "pci-0000:01:00.0-scsi-0:0:8:0" ]]; then
        BAY=8
        echo $BAY is used for mounting $DEVICE >> /tmp/testudev.log
fi
success="FAILED"
## body for the api post
generate_post_data()
{
  cat <<EOF
{
  "OR_ID": "$LABEL",
  "status": "$success",
  "disk_serial": "$ID_SERIAL_SHORT",
  "cp": "Not updated yet"
}
EOF
}


# See if this drive is already mounted, and if so where
MOUNT_POINT=$(/bin/mount | /bin/grep ${DEVICE} | /usr/bin/awk '{ print $3 }')

do_mount()
{
	### If you want to mount FUSE-based filesystems like NTFS, 
	### your script has to quit the control group in which udev puts it in order to avoid getting killed prematurely:
	echo $$ > /sys/fs/cgroup/systemd/tasks

    if [[ -n "${MOUNT_POINT}" ]]; then
        echo "Warning: ${DEVICE} is already mounted at ${MOUNT_POINT}"
        exit 1
    fi

    # Get info for this drive: $ID_FS_LABEL, $ID_FS_UUID, and $ID_FS_TYPE
    # added some sed's to avoid space issues
    eval $(/sbin/blkid -o udev ${DEVICE}|sed 's/=/="/'|sed 's/$/"/')

    # Figure out a mount point to use
    LABEL="${ID_FS_LABEL}"
    if [[ -z "${LABEL}" ]]; then
        LABEL="UNKNOW"
    elif /bin/grep -q " /export/home/${LABEL} " /etc/mtab; then
        # Already in use, make a unique one
	exit 1
    fi
    MOUNT_POINT="/export/home/${LABEL}"

    echo "Mount point: ${MOUNT_POINT}"

    /bin/mkdir -p "${MOUNT_POINT}"

    # Global mount options
    OPTS="rw,relatime"
    # File system type specific mount options
    if [[ ${ID_FS_TYPE} == "vfat" ]]; then
        OPTS+=",users,gid=100,umask=000,shortname=mixed,utf8=1,flush"
    #added options I wanted on ntfs
    elif [[ ${ID_FS_TYPE} == "exfat" ]]; then
        OPTS+=",user,users,umask=000,allow_other"
    else
       echo "not sure what kind of disk this is"
    fi

## Mounting disk

    if ! /bin/mount -o "${OPTS}" ${DEVICE} "${MOUNT_POINT}"; then
        echo "Error mounting ${DEVICE} (status = $?)"
        /bin/rmdir "${MOUNT_POINT}"
        exit 1

### update state db with the api exit if fails and do not mount
	else  success="Mounted" &&\
	curl -i \
		-H "Accept: application/json" \
		-H "Content-Type:application/json" \
		-X PUT --data "$(generate_post_data)" "http://${APIIP}:8081/Bays/${BAY}" 
    fi


    echo "**** Mounted ${DEVICE} at ${MOUNT_POINT} ****"
	sleep 2
	success="Mounted"
	echo "**** Mounted ${DEVICE} at ${MOUNT_POINT} **** using ${BAY}" > ${MOUNT_POINT}/olixir.nfo

### update state db with the api exit if fails and do not mount
#curl -i \
#-H "Accept: application/json" \
#-H "Content-Type:application/json" \
#-X PUT --data "$(generate_post_data)" "http://${APIIP}:8081/Bays/${BAY}" || exit 1
}

do_unmount()
{
    if [[ -z ${MOUNT_POINT} ]]; then
        echo "Warning: ${DEVICE} is not mounted"
    else
        /bin/umount -l ${DEVICE}
        echo "**** Unmounted ${DEVICE}"
    fi

    # Delete all empty dirs in /media that aren't being used as mount
    # points. This is kind of overkill, but if the drive was unmounted
    # prior to removal we no longer know its mount point, and we don't
    # want to leave it orphaned...
    for f in /export/home/* ; do
        if [[ -n $(/usr/bin/find "$f" -maxdepth 0 -type d -empty) ]]; then
            if ! /bin/grep -q " $f " /etc/mtab; then
                echo "**** Removing mount point $f"
                /bin/rmdir "$f"
            fi
        fi
    done
    ## remove from database with api
    echo "*****removeing from db bay ${BAY}"
    curl -X DELETE "http://${APIIP}:8081/Bays/${BAY}" -H "accept: */*"
}

case "${ACTION}" in
    add)
        do_mount
        ;;
    remove)
        do_unmount
        ;;
    *)
        usage
        ;;
 esac
