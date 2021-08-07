#!/bin/bash
PROTON=~/.local/share/Steam/compatibilitytools.d/Proton-6.12-GE-1/proton
STEAM_INSTALL_PATH="/opt/steam/steamapps/common/FEAR Ultimate Shooter Edition"
export STEAM_COMPAT_CLIENT_INSTALL_PATH=~/.steam 
export STEAM_COMPAT_DATA_PATH=/opt/steam/steamapps/compatdata/21090
cd "$STEAM_INSTALL_PATH"
$PROTON run FEARMP.exe -archcfg Coop-Warfare_0.7.archcfg -userdirectory Coopwarfare_User
cd -
