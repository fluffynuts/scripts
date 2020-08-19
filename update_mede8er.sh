#!/bin/bash
MEDESYNC="ionice -c idle $(dirname $0)/medesync.py"
BITSPLAT="ionice -c idle $(dirname $0)/bitsplat --no-history"

# fixme: bitsplat is not moving source files to the archive folder
#NO_BITSPLAT=1
NO_MEDESYNC=1

SPECIFIED_TARGET="$1"
SRC_BASE=/mnt/monolith
if test -z "$DST_BASE"; then
  DST_BASE=/mnt/mede8er-smb
fi
PIDFILE=/tmp/update-mede8er.pid

if test ! -z "$LOG_TO_FILE"; then
    LOGFILE=/tmp/update-mede8er.log
    echo "PID $$ started at: $(date "+%Y-%m-%d_%H.%M.%S")" >> $LOGFILE
fi
if test ! -z "$DUMMY"; then
    DUMMY="-dummy"
fi

function check_single() {
    OTHER=""
    if test -e $PIDFILE; then
        OTHER="$(cat $PIDFILE)"
    fi
    if test ! -z "$OTHER"; then
        if test -e /proc/$OTHER; then
            if test ! -z "$(cat /proc/$OTHER/cmdline | grep $0)"; then
                if test -z "$IN_CRON"; then
                  echo "Already running with pid $OTHER"
                fi
                exit 1
            fi
        fi
    fi
    echo $$ > $PIDFILE
}

function clear_pidfile() {
    if test -e $PIDFILE; then
        rm -f $PIDFILE
    fi
}

function puts() {
    if test -z "$LOGFILE"; then
        echo $1
    else
        echo $1 >> "$LOGFILE"
    fi
}

function update_target_with_bitsplat() {
    TARGET="$1"
    ARCHIVE="$2"
    if test ! -z "$SPECIFIED_TARGET"; then
        if test ! "$SPECIFIED_TARGET" = "$TARGET"; then
            puts "Skipping $TARGET"
            return
        fi
    fi
    puts "=== Syncing: $TARGET $(date -Iseconds) ==="
    if ! test -d $DST_BASE/$TARGET; then
        mkdir $DST_BASE/$TARGET
    fi

    CMD="$BITSPLAT --source $SRC_BASE/$TARGET --target $DST_BASE/$TARGET"
    if test ! -z "$QUIET"; then
      CMD="$CMD --quiet"
    fi
    if test ! -z "$ARCHIVE"; then
      if ! test -d "$ARCHIVE"; then
        mkdir -p "$ARCHIVE"
      fi
      CMD="$CMD --archive $ARCHIVE"
    fi
    if test ! -z "$NO_HISTORY"; then
      CMD="$CMD --no-history"
    fi
    if test "$TARGET" = "keep"; then
      CMD="$CMD --keep-stale"
    fi
    if test ! -z "$LOGFILE"; then
      CMD="$CMD >> $LOGFILE"
    fi
    puts "Run bitsplat: $CMD"
    if test -z "$LOGFILE"; then
      $CMD
    else
      $CMD >> $LOGFILE
    fi
}

function update_target_with_medesync() {
    TARGET="$1"
    ARCHIVE="$2"
    if test ! -z "$SPECIFIED_TARGET"; then
        if test ! "$SPECIFIED_TARGET" = "$TARGET"; then
            puts "Skipping $TARGET"
            return
        fi
    fi
    puts "=== Syncing: $TARGET ==="
    if ! test -d $DST_BASE/$TARGET; then
        mkdir $DST_BASE/$TARGET
    fi
    CMD="$MEDESYNC -s $SRC_BASE/$TARGET -d $DST_BASE/$TARGET $DUMMY"
    if test ! -z "$LOGFILE"; then
      CMD="$CMD -l $LOGFILE"
    fi
    if test -z "$ARCHIVE"; then
        $CMD
    else
        if ! test -d "$ARCHIVE"; then
            mkdir -p "$ARCHIVE"
        fi
        $CMD -a $ARCHIVE
    fi
}

function update_target() {
  if test -z "$NO_BITSPLAT"; then
    puts "Attempt update with bitsplat"
    update_target_with_bitsplat $*
  fi
  if test -z "$NO_MEDESYNC"; then
    puts "Attempt update with medesync"
    update_target_with_medesync $*
  fi
}

function check_target_is_mounted() {
    if test -z "$(mount | grep $DST_BASE)"; then
        puts "FATAL: mede8er does not appear to be mounted!"
        exit 2
    fi
    puts "$DST_BASE is mounted... let the fun begin"
}

function attempt_target_remount() {
    if test ! -z "$SKIP_REMOUNT"; then
      return
    fi
    puts "Attempting remount of $DST_BASE"
    attempt_target_dismount
    mount $DST_BASE
}

function attempt_target_dismount() {
    if test ! -z "$SKIP_REMOUNT"; then
      return
    fi
    if test ! -z "$(mount | grep $DST_BASE)"; then
      umount $DST_BASE
    fi
}

function log_complete() {
  puts "Sync complete."
}

function sweep_target() {
  $(dirname $0)/sweep-mede8er
}

check_single
attempt_target_remount
check_target_is_mounted
update_target series /mnt/piggy/series/watched
update_target movies /mnt/piggy/movies/watched
SRC_BASE=/mnt/archive
update_target keep
clear_pidfile
log_complete
sweep_target
attempt_target_dismount
