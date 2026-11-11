#!/bin/sh
# Stop the Strata server and engine by PID.
# Never pkill -f strata: that pattern matches this script's own command
# line and would kill the caller instead of the server (see MY-SETUP.md).

# Collect PIDs only, skipping this script's own process.
server_pids=""
engine_pids=""
for pid in $(pgrep -f 'server.py --engine'); do
    [ "$pid" != "$$" ] && server_pids="$server_pids $pid"
done
for pid in $(pgrep -f 'engine/strata'); do
    [ "$pid" != "$$" ] && engine_pids="$engine_pids $pid"
done

if [ -z "$server_pids$engine_pids" ]; then
    echo "Nothing to stop: no server.py --engine or engine/strata process found."
    exit 0
fi

echo "Server PIDs:$server_pids"
echo "Engine PIDs:$engine_pids"

# Kill the server first so it does not respawn the engine, then the engine.
for pid in $server_pids $engine_pids; do
    kill "$pid" 2>/dev/null && echo "Sent SIGTERM to $pid"
done

# Give them a few seconds to shut down cleanly; escalate to SIGKILL if needed.
i=0
while [ $i -lt 10 ]; do
    alive=""
    for pid in $server_pids $engine_pids; do
        kill -0 "$pid" 2>/dev/null && alive="$alive $pid"
    done
    [ -z "$alive" ] && break
    sleep 1
    i=$((i + 1))
done

for pid in $server_pids $engine_pids; do
    if kill -0 "$pid" 2>/dev/null; then
        echo "Still alive after 10 s, sending SIGKILL to $pid"
        kill -9 "$pid"
    fi
done

echo "Strata stopped."
