#!/bin/sh
# $bing is needed to form the fully qualified URL for
# the Bing pic of the day
bing="www.bing.com"

# The idx parameter determines where to start from. 0 is the current day,
# 1 the previous day, etc.
idx="0"

# $xmlURL is needed to get the xml data from which
# the relative URL for the Bing pic of the day is extracted
xmlURL="http://www.bing.com/HPImageArchive.aspx?format=xml&idx=$idx&n=1&mkt=$mkt"

# $saveDir is used to set the location where Bing pics of the day
# are stored.  $HOME holds the path of the current user's home directory
saveDir=$HOME'/Pictures/Bing/'

# The file extension for the Bing pic
picExt=".jpg"

# Create saveDir if it does not already exist
mkdir -p $saveDir

for picRes in _1920x1200 _1920x1080 _1366x768 _1280x720 _1024x768; do

# Extract the relative URL of the Bing pic of the day from
# the XML data retrieved from xmlURL, form the fully qualified
# URL for the pic of the day, and store it in $picURL
picURL=$bing$(echo $(curl -s $xmlURL) | grep -oP "<urlBase>(.*)</urlBase>" | cut -d ">" -f 2 | cut -d "<" -f 1)$picRes$picExt

# $picName contains the filename of the Bing pic of the day
picName=${picURL##*/}

# Download the Bing pic of the day
curl -s -o $saveDir$picName -L $picURL

# Test if download was successful.
downloadResult=$?
if [[ $downloadResult -ge 1 ]]; then
    rm -rf $saveDir$picName && continue
fi
echo "Downloaded: $saveDir$picName"

# Test if it's a pic
file --mime-type -b $saveDir$picName | grep "^image/" > /dev/null && break

rm -rf $saveDir$picName
done
