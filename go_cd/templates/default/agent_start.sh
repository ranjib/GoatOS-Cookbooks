#!/bin/bash

if [ -f /etc/default/go-agent ]; then
    echo "[`date`] using default settings from /etc/default/go-agent"
    . /etc/default/go-agent
fi

CWD=`dirname "$0"`
AGENT_DIR=`(cd "$CWD" && pwd)`

AGENT_MEM=${AGENT_MEM:-"128m"}
AGENT_MAX_MEM=${AGENT_MAX_MEM:-"256m"}
GO_SERVER=${GO_SERVER:-"127.0.0.1"}
GO_SERVER_PORT=${GO_SERVER_PORT:-"8153"}
JVM_DEBUG_PORT=${JVM_DEBUG_PORT:-"5006"}
VNC=${VNC:-"N"}
LOG_FILE=/var/log/go-agent/go-agent-bootstrapper.log
PID_FILE=/var/run/go-agent/go-agent.pid
AGENT_STARTUP_ARGS="-Dcruise.console.publish.interval=10 -Xms$AGENT_MEM -Xmx$AGENT_MAX_MEM $JVM_DEBUG $GC_LOG $GO_AGENT_SYSTEM_PROPERTIES"
export AGENT_STARTUP_ARGS
export LOG_DIR
export LOG_FILE

CMD="$JAVA_HOME/bin/java -jar \"$AGENT_DIR/agent-bootstrapper.jar\" $GO_SERVER $GO_SERVER_PORT"

echo "[`date`] Starting Go Agent Bootstrapper with command: $CMD" >>$LOG_FILE
echo "[`date`] Starting Go Agent Bootstrapper in directory: $AGENT_WORK_DIR" >>$LOG_FILE
echo "[`date`] AGENT_STARTUP_ARGS=$AGENT_STARTUP_ARGS" >>$LOG_FILE
cd "$AGENT_WORK_DIR"

if [ "$JAVA_HOME" == "" ]; then
    echo "Please set JAVA_HOME to proceed."
    exit 1
fi

if [ "$DAEMON" == "Y" ]; then
    eval "nohup $CMD >>$LOG_FILE &"
    echo $! >$PID_FILE
else
    eval "$CMD"
fi
