#!/bin/bash
#dst_base="ftp://daf:h4xx0r@mede8er-w"
dst_base="/mnt/olddump"
LOGFILE=stdout

function remount() {
  return;
  if test -e "$dst_base"; then
    if test ! -z "$(mount | grep $dst_base)"; then
      echo "Unmounting $dst_base"
      umount "$dst_base"
    fi
    if test -z "$(mount | grep $dst_base)"; then
      echo "Mounting $dst_base"
      mount "$dst_base"
    fi
    if test -x "$(mount | grep $dst_base)"; then
      echo "$dst_base not mounted and unable to mount; aborting"
      exit 2
    fi
  fi
}

function __reboot_mede8er() {
    if test -z "$NO_REBOOT"; then
      if test -e $(dirname $0)/reboot_mede8er; then
        echo "rebooting mede8er..."
        $(dirname $0)/reboot_mede8er
        echo -n "Waiting a little while"
        for ((i = 0; i < 35; i++)); do
          echo -n "."
          sleep 1
        done
      fi
      echo ""
    fi
}

function sync_targets() {
  remount
  synced=0
  for d in $(echo $TARGETS); do
    if test -e "${src_base}/${d}"; then
      if test "$LOGFILE" = "stdout"; then
        echo " === syncing $d ==="
        $SS -s $src_base/$d/new -d $dst_base/$d -a $src_base/$d/watched
      else
        echo " === syncing $d ===" >> $LOGFILE
        $SS -s $src_base/$d/new -d $dst_base/$d -a $src_base/$d/watched -l $LOGFILE
      fi
      let "synced = $synced + 1"
    fi
  done
}
SS=/home/daf/apps/scripts/medesync.py
PIDFILE="/tmp/init_mede8er.pid"
if test -z "$LOGFILE"; then
  LOGFILE="/tmp/update_mede8er-$$.log"
fi
if test -f $PIDFILE; then
	OTHERPID=$(cat $PIDFILE)
	OTHERPROCESS=$(ps -p $OTHERPID -o comm=)
	if test ! -z "$OTHERPROCESS"; then
		echo "Bailing out: mede8er update already running with pid $OTHERPID"
		exit 1
	fi
fi

echo -n "$$" > $PIDFILE

if test -d "$dst_base"; then
  if test -z "$(mount | grep $dst_base)"; then
    echo "$dst_base not mounted; attempting to mount now"
    mount $dst_base
    if test -z "$(mount | grep $dst_base)"; then
      echo "Can't mount or find mount $dst_base"
      exit 1
    fi
  fi
fi

src_base="/mnt/piggy"

if test -z "$1"; then
  TARGETS="movies"
  sync_targets
else
  TARGETS="$1"
  sync_targets
  if test "$synced" = "0"; then
    exit 0
  fi
fi

if test -z "$1" || test "$1" = "keep"; then
  echo " === synching keep ==="
  $SS -s $src_base/keep -d $dst_base/keep -l $LOGFILE
  if test "$TARGETS" != "$1"; then
      $SS -s $src_base/$d/new -d $dst_base/$d -a $src_base/$d/watched
  fi
  rm -f $PIDFILE
fi

src_base="/mnt/elements"
if test -z "$1"; then
  TARGETS="series"
  sync_targets
else
  TARGETS="$1"
  sync_targets
  if test "$synced" = "0"; then
    exit 0
  fi
fi

src_base="/mnt/piggy"

if test -z "$1"; then
  TARGETS="animated"
  sync_targets
else
  TARGETS="$1"
  sync_targets
  exit 0
fi



