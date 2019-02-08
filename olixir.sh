#!/bin/bash
## olixir Daemon script 
# args:
#   start:
#     Starts a olixir watcher and worker Daemon
#   stop:
#     Kills the watcher and the worker
#   status:
#     Checks if there is a daemon running
##
pidFile=./olixir.pid
cmds() {
    trap "exit" INT TERM ERR
    trap "kill 0" EXIT
    uwsgi --chunked-input-timeout 300 uwsgi_local.ini --pidfile ./uwsgi.pid &
    watcherPid=`echo $$`
    echo  $watcherPid > $pidFile
    wait
    rm $pidFile  &> /dev/null
}

checkrunning() {
 if [ -f "$pidFile" ] &&  ps aux | grep $(cat olixir.pid) | head -n1 | egrep $0 1>/dev/null  ;then
  return 0
 else echo "*  olixir service is not running ...." & return 1
 fi
}

case "$1" in
  start) 
    if [ -f "$pidFile" ] && checkrunning ; then
      oldPid=`cat "$pidFile"`
      echo "* olixir service is already running with PID  ${oldPid}"
    else cmds   
    fi  
    ;;
  stop)
    uwsgi --stop ./uwsgi.pid
    if [ -f "$pidFile" ]; then
      echo "* olixir service will die... killing PID `cat $pidFile` ..." 
      kill -TERM `cat $pidFile` 
      rm $pidFile
    else echo "* olixir service is NOT running .."
    fi
    ;;
  status)
    if checkrunning ;then
      echo "* olixir service is running with main PID `cat $pidFile`"
    fi
    ;;
   log)
    less olixir.log
    ;;

  *)
  echo "Error: usage $0 { start | stop | status | log}"
  exit 1
esac

exit 0

