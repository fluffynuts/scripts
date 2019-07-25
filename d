#!/bin/zsh
PRIOR_LAST_JOB_NUMBER=$(jobs | tail -n 1 | grep -i '[0-9]')
$@ &> /dev/null &
JOB_NUMBER=$(jobs | tail -n 1 | grep -i '[0-9]')
# job may exit really quickly -- only disown if we've added a new one
if test "$PRIOR_LAST_JOB_NUMBER" -ne "$JOB_NUMBER"; then
  disown $JOB_NUMBER
fi
