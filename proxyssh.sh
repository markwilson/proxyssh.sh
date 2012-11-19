#!/bin/bash

# source finder borrowed from http://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
# end of source finder

PROFILE="$1"

# check if profile is provided
if [ -r $PROFILE ]
then
	echo "Usage: $0 <profile>"
	exit 1
fi

# load profile data
PROFILE=`echo $PROFILE | sed 's/\.conf$//'`
PROFILEPATH="$DIR/proxyssh.d/$PROFILE.conf"

# check profile exists
if [ ! -f $PROFILEPATH ]
then
	echo "Could not file profile \"$PROFILE\""
	exit 1
fi

. $PROFILEPATH

ERRORS=false

# no remote host
if [ -r $REMOTEHOST ]
then
	ERRORS=true
	echo "No REMOTEHOST specified"
fi

# no proxy host
if [ -r $PROXYHOST ]
then
	ERRORS=true
	echo "No PROXYHOST specified"
fi

$ERRORS && exit 1;

# remote user
if [ -r $REMOTEUSER ]
then
	REMOTEUSER=""
else
	REMOTEUSER="$REMOTEUSER@"
fi

# proxy user
if [ -r $PROXYUSER ]
then
	PROXYUSER=""
else
	PROXYUSER="$PROXYUSER@"
fi


# good defaults
if [ -r $LOCALHOST ]
then
	LOCALHOST="127.0.0.1"
fi
if [ -r $LOCALPORT ]
then
	LOCALPORT=10022
fi
if [ -r $REMOTEPORT ]
then
	REMOTEPORT=22
fi
if [ -r $PROXYPORT ]
then
	PROXYPORT=22
fi

# helper variables
PROCESSCOMMAND="netstat -tlpn"
LOCAL="$LOCALHOST:$LOCALPORT"
REMOTE="$REMOTEHOST:$REMOTEPORT"

# check if a process already exists on these ports
EXISTS=`$PROCESSCOMMAND 2> /dev/null | grep "$LOCAL" -c`
if [ $EXISTS -eq 1 ]
then
	EXISTINGPID=`$PROCESSCOMMAND 2> /dev/null | grep "$LOCAL" | sed 's/ *$//' | sed 's/^.*[\t ]\([^ \t]*\)\/[^\t ]*$/\1/'`
	echo "Port is being used by process: $EXISTINGPID"
	exit 1
fi

PID=0

# handle interrupt
trap '{ test $PID -gt 0 && kill $PID && exit 1; exit 0; }' INT

# connect through proxy
echo "Connecting to proxy ($PROXYHOST:$PROXYPORT) ..."
ssh -f -L $LOCAL:$REMOTE $PROXYUSER$PROXYHOST -p $PROXYPORT -N 

# keep a copy of the process ID
PID=`$PROCESSCOMMAND 2> /dev/null | grep "$LOCAL" | sed 's/ *$//' | sed 's/^.*[ \t]\([^ \t]*\)\/[^ \t]*$/\1/'`

# make connection via tunnel
echo "Connecting to remote ($REMOTE) via local ($LOCAL) ..."
ssh $REMOTEUSER$LOCALHOST -p $LOCALPORT

# clean up
kill $PID
