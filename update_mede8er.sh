#!/bin/bash
MEDESYNC="ionice -c idle /home/daf/apps/scripts/medesync.py"
SPECIFIED_TARGET="$1"
SRC_BASE=/mnt/monolith
if test -z "$DST_BASE"; then
  DST_BASE=/mnt/mede8er-smb
fi
PIDFILE=/tmp/update-mede8er.pid

if test -z "$LOGFILE"; then
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
    if test "$LOGFILE" = "stdout"; then
        echo $1
    else
        echo $1 >> "$LOGFILE"
    fi
}

function update_target() {
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
    CMD="$MEDESYNC -s $SRC_BASE/$TARGET -d $DST_BASE/$TARGET -l $LOGFILE $DUMMY"
    if test -z "$ARCHIVE"; then
        $MEDESYNC -s $SRC_BASE/$TARGET -d $DST_BASE/$TARGET -l $LOGFILE $DUMMY
    else
        if ! test -d "$ARCHIVE"; then
            mkdir -p "$ARCHIVE"
        fi
        $CMD -a $ARCHIVE
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

check_single
attempt_target_remount
check_target_is_mounted
update_target series /mnt/piggy/series/watched
update_target movies /mnt/piggy/movies/watched
SRC_BASE=/mnt/archive
update_target keep
clear_pidfile
log_complete
attempt_target_dismount
