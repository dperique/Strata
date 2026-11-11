#!/bin/sh
# Start the Strata server, following the quick-start sequence in MY-SETUP.md.
cd "/home/dperique/mygit/dperique/NG/Dennis/Redhat/Strata" || exit 1

# Skip if it is already up.
if curl -s -m 3 http://127.0.0.1:8080/health | grep -q '"loaded": true'; then
    echo "Already running:"
    curl -s http://127.0.0.1:8080/health
    exit 0
fi

# Confirm the settings are still right BEFORE starting. Never run setup.sh to
# "fix" them - it resets anything you don't restate.
want_context=$(grep -A1 '"--max-context"' strata-iq2_xs.json | grep -o 262144)
want_reserve=$(grep -A1 '"--vram-reserve-mib"' strata-iq2_xs.json | grep -o 960)
if [ "$want_context" != 262144 ] || [ "$want_reserve" != 960 ]; then
    echo "WARNING: strata-iq2_xs.json does not have --max-context 262144 and --vram-reserve-mib 960."
    echo "Current values:"
    grep -A1 -E '"--max-context"|"--vram-reserve-mib"' strata-iq2_xs.json
    echo "Starting anyway; fix the settings if this is not what you want."
fi

echo "Starting Strata (~30 s; up to 1-3 min after a reboot). The PC may freeze for"
echo "1-3 min while 39 GB loads into RAM - that is normal, don't kill it."
nohup ./run-iq2_xs.sh > strata-server.out 2>&1 &
server_pid=$!
echo "Server PID: $server_pid"

# Poll until it answers (expect "loaded": true in about 30 s).
i=0
while [ $i -lt 36 ]; do
    if curl -s -m 3 http://127.0.0.1:8080/health | grep -q '"loaded": true'; then
        break
    fi
    sleep 5
    i=$((i + 1))
done

if [ $i -ge 36 ]; then
    echo "Timed out after 3 minutes. Check strata-server.out for errors."
    exit 1
fi

curl -s http://127.0.0.1:8080/health

# Verify the 256k context three ways: what the server advertises ...
curl -s http://127.0.0.1:8080/v1/models
# ... and what the engine was actually started with (the ground truth).
tr '\r' '\n' < strata-iq2_xs.log | grep 'engine started:' | tail -1
grep 'context 262144 tokens' strata-server.out

# Smoke test. Low reasoning effort - high burns the whole output budget on thinking.
curl -s http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
  -d '{"model":"qwen3.8-flash-next-iq2_xs","messages":[{"role":"user","content":"Say OK"}],"max_tokens":16,"reasoning_effort":"low"}'

echo
echo "Done when /health above says \"loaded\": true with \"max_context\": 262144 and the smoke test returns content."
