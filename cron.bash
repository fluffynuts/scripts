#!/bin/bash
set -e

source /etc/environment
source /etc/profile
source /home/daf/.profile
source /home/daf/.bashrc
source /home/daf/.nvm/nvm.sh

SHELL=/bin/bash

exec /bin/bash --norc "$@"
