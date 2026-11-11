#!/bin/sh
# Report Strata's status: is it up, which PIDs, and what the logs say.
# The quick summary is at the BOTTOM so you can focus on it.
cd "/home/dperique/mygit/dperique/NG/Dennis/Redhat/Strata" || exit 1

echo "== Processes =="
server_pids=""
engine_pids=""
for pid in $(pgrep -f 'server.py --engine'); do
    [ "$pid" != "$$" ] && server_pids="$server_pids $pid"
done
for pid in $(pgrep -f 'engine/strata'); do
    [ "$pid" != "$$" ] && engine_pids="$engine_pids $pid"
done
echo "Server PIDs:$server_pids"
echo "Engine PIDs:$engine_pids"

echo
echo "== Health =="
health=$(curl -s -m 3 http://127.0.0.1:8080/health)
if [ -z "$health" ]; then
    echo "No answer from http://127.0.0.1:8080/health - not running."
else
    echo "$health"
fi

echo
echo "== Ground truth (what the engine was actually started with) =="
tr '\r' '\n' < strata-iq2_xs.log | grep 'engine started:' | tail -1
grep 'context 262144 tokens' strata-server.out | tail -1

echo
echo "== Recent logs =="
echo "--- strata-server.out (last 10 lines) ---"
tail -10 strata-server.out
echo "--- strata-iq2_xs.log (last 10 lines) ---"
tr '\r' '\n' < strata-iq2_xs.log | tail -10

# Quick summary last, so it is the last thing you see.
echo
echo "== Summary =="
if [ -z "$health" ]; then
    running=no; loaded=no; context=no; images=no
else
    running=yes
    echo "$health" | grep -q '"loaded": true' && loaded=yes || loaded=no
    echo "$health" | grep -q '"max_context": 262144' && context=yes || context=no
    echo "$health" | grep -q '"images": true' && images=yes || images=no
fi
echo "Running: $running   Loaded: $loaded   Context 262144: $context   Images: $images"
echo "Server PIDs:$server_pids"
echo "Engine PIDs:$engine_pids"
