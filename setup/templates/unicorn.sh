#!/bin/sh

### BEGIN INIT INFO
# Provides:          unicorn
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: unicorn
# Description:       unicorn
### END INIT INFO

set -e
TIMEOUT=${TIMEOUT-100}
APP_ROOT=/puzzle/app/current
PID=$APP_ROOT/tmp/pids/unicorn.pid
export PATH=/puzzle/ruby-2.5.0/bin:/puzzle/node-8.12/bin:$PATH
CMD="bundle exec unicorn -D -E {{RAILS_ENV}} -c $APP_ROOT/config/unicorn.rb"
action="$1"
set -u

old_pid="$PID.oldbin"

cd $APP_ROOT || exit 1

sig () {
  test -s "$PID" && kill -$1 `cat $PID`
}

oldsig () {
  test -s $old_pid && kill -$1 `cat $old_pid`
}

case $action in
start)
  sig 0 && echo >&2 "Already running" && exit 0
  eval $CMD
  ;;
stop)
  sig QUIT && exit 0
  echo >&2 "Not running"
  ;;
force-stop)
  sig TERM && exit 0
  echo >&2 "Not running"
  ;;
restart|reload)
  sig HUP && echo reloaded OK && exit 0
  echo >&2 "Couldn't reload, starting '$CMD' instead"
  eval "$CMD"
  ;;
status)
  current_pid=`cat $PID`
  status=`ps -p $current_pid > /dev/null 2>&1`
  exit $status
  ;;

upgrade)
  # via http://www.rostamizadeh.net/blog/2012/03/09/wrangling-unicorn-usr2-signals-and-capistrano-deployments/
  if test -s $PID; then ORIG_PID=`cat $PID`; else ORIG_PID=0; fi

  echo 'Original PID: ' $ORIG_PID

  if sig USR2
  then
    echo 'USR2 sent; Waiting for .oldbin'
    n=$TIMEOUT

    #wait for .oldpid to be written
    while (!(test -s $old_pid) && test $n -ge 0)
    do
      printf '.' && sleep 3 && n=$(( $n - 1 ))
    done

    echo 'Waiting for new pid file'
    #when this loop finishes, should have new pid file
    while (!(test -s $PID ) || test -s $old_pid) && test $n -ge 0
    do
      printf '.' && sleep 3 && n=$(( $n - 1 ))
    done

    if test -s $PID
    then
      NEW_PID=`cat $PID`
    else
      echo 'New master failed to start; see error log'
      exit 1
    fi

    #timeout has elapsed, verify new pid file exists
    if [ $ORIG_PID -eq $NEW_PID ]
    then
      echo
      echo >&2 'New master failed to start; see error log'
      exit 1
    fi

    echo 'New PID: ' $NEW_PID

    #verify old master QUIT
    echo
    if test -s $old_pid
    then
      echo >&2 "$old_pid still exists after $TIMEOUT seconds"
      exit 1
    fi

    printf 'Unicorn successfully upgraded'
    exit 0
  fi
  echo >&2 "Upgrade failed: executing '$CMD' "
  eval "$CMD"
  ;;



reopen-logs)
  sig USR1
  ;;
*)
  echo >&2 "Usage: $0 <start|stop|restart|upgrade|force-stop|reopen-logs>"
  exit 1
  ;;
esac
