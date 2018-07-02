#!/bin/bash
#dst_base="ftp://daf:h4xx0r@mede8er-w"
dst_base="/media/daf/Dump2"
LOGFILE=stdout

function sync_targets() {
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
PIDFILE="/tmp/update_mede8er.pid"
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
#__reboot_mede8er

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

exit 0
src_base="/mnt/piggy"

if test -z "$1"; then
  TARGETS="animated"
  sync_targets
else
  TARGETS="$1"
  sync_targets
  exit 0
fi



