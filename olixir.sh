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
cmds() {
    trap "exit" INT TERM ERR
    trap "kill 0" EXIT
    uwsgi --chunked-input-timeout 300 uwsgi_local.ini --pidfile ./uwsgi.pid &
    watcherPid=`echo $$`
    wait
}


case "$1" in
  start)
   cmds
    ;;
  stop)
    uwsgi --stop ./uwsgi.pid
    ;;
   log)
    less olixir.log
    ;;
  *)
  echo "Error: usage $0 { start | stop | status | log}"
  exit 1
esac

exit 0

