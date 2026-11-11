# My Strata setup — start, stop, monitor

Personal notes. Project docs are in `docs/`.

## Quick start — the whole sequence in one block

Three scripts in the repo root do the whole sequence:

```sh
cd ~/mygit/dperique/NG/Dennis/Redhat/Strata
./start.sh      # start, poll until loaded, verify 256k, smoke test
./status.sh     # processes, health, ground truth, recent logs; summary at the bottom
./stop.sh       # kill server and engine by PID
```

`start.sh` does the full sequence below in order: skips if already up, checks the settings in
`strata-iq2_xs.json` first (never runs setup.sh to "fix" them — it resets anything you don't
restate), starts the server, polls until `"loaded": true`, verifies the 256k context three ways,
and runs the smoke test with low reasoning effort. The manual commands are kept below as the
reference for what the scripts do.

Done when `/health` returns `"loaded": true` with `"max_context": 262144` and the smoke test
returns content. Details on stopping, logs and the traps are below.

## What's installed

| | |
| --- | --- |
| Model | `qwen3.8-flash-next-iq2_xs` (Qwen3.8-Flash-Next, IQ2_XS) |
| Engine | CUDA, RTX 4090 24 GB, driver 617.14 |
| Context | 262144 tokens |
| Output cap | 32768 tokens (set in **opencode.json**, not here) |
| Images | `--vision gpu` — the encoder on the RTX 4090 (~1.4 GB VRAM, 0.1-0.5 s per picture) |
| VRAM reserve | 960 MiB kept free for the display driver |
| KV cache | 8-bit. KV streaming **off** — this is WSL2, which cannot pin the RAM copy |
| Port | 8080, bound to 127.0.0.1, **no API key** |
| Model files | `../Strata-data` — 72 GB. Deleting this means a re-download |

## Start

```sh
cd ~/mygit/dperique/NG/Dennis/Redhat/Strata
./start.sh
```

Or the raw command the script runs:

```sh
nohup ./run-iq2_xs.sh > strata-server.out 2>&1 &
```

Takes 30–90 s to load the model; longer the first time after a reboot. Loading 39 GB into RAM
can make the PC unresponsive for 1–3 minutes — that is normal, don't kill it.

## Stop

```sh
./stop.sh
```

It finds the PIDs itself, kills the server first then the engine, waits 10 s, and escalates to
SIGKILL only for anything still alive. The manual version:

```sh
pgrep -af 'server.py --engine'
pgrep -af 'engine/strata'
kill <server-pid> <engine-pid>
```

**Kill by PID, never `pkill -f strata`** — that pattern also matches your own shell's command
line and will kill your terminal instead of the server. This wasted two attempts. `stop.sh`
excludes its own process for this reason.

## Is it up?

```sh
./status.sh
```

Shows processes, health, the ground-truth lines, and recent logs, with the quick summary at the
bottom. The one-liner version:

```sh
curl -s http://127.0.0.1:8080/health
```

Healthy means `"loaded": true` and `"max_context": 262144`. No answer = not running.

## Logs — the ground truth

```sh
tail -f strata-server.out                     # server: requests, speeds, the cap the client sent
tr '\r' '\n' < strata-iq2_xs.log | tail -30   # engine: VRAM, expert cache, warnings
```

Trust `strata-server.out` over the Monitor page or the TUI — both only echo what the client
claims. The line `thinking: N of max M tokens` shows the real output cap in force.

## Images

`/health` must say `"images": true` (it did, after the 2026-10-17 vision setup). Test one end to
end before trusting a client:

```sh
curl -s http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
 -d '{"model":"qwen3.8-flash-next-iq2_xs","max_tokens":60,"reasoning_effort":"low",
      "messages":[{"role":"user","content":[
        {"type":"text","text":"One short sentence: what shape and color is in this image?"},
        {"type":"image_url","image_url":{"url":"data:image/png;base64,<base64>"}}]}]}'
```

Base64 data URIs and `http(s)` URLs both work. Measured: a 320x240 PNG answered in 1.3 s end to
end on the GPU encoder. The encoder runs only while the engine is idle, so a picture adds
0.1-0.5 s before the answer starts. `"max_tokens": 1024` in the config is the image-token cap
(`--vision-tokens N` to change it).

## Settings that must not be lost

`--max-context 262144`, `--vram-reserve-mib 960` and `--vision gpu` live in `strata-iq2_xs.json`.
(The backup before vision was added is `strata-iq2_xs.json.bak-2026-10-17`; setup itself also
keeps the previous one as `strata-iq2_xs.json.bak`.)

**`./setup.sh --setup` with any flag resets every setting you don't restate.** Passing only
`--vram-reserve-mib 960` silently dropped the context back to 131072. Always restate all of them:

```sh
./setup.sh --yes --setup --family qwen --model IQ2_XS --context 262144 --kv int8 \
  --vram-reserve-mib 960 --vision gpu --no-start
```

## After a reboot or if WSL dies

1. Open a WSL terminal (`wsl` from Windows). WSL2 shuts its VM down when idle, which also
   kills Strata — this is the most likely reason it's "just not there".
2. Start it with `./start.sh`.
3. Check `/health` (or `./status.sh`).

There is **no autostart** — no systemd unit, no scheduled task. It will not come back on its own.

## Two traps worth remembering

- **Output truncation.** An answer that stops mid-sentence with `finish_reason: length` hit the
  output cap, not a model problem. It was 8192 (my fault in opencode.json); now 32768.
- **Reasoning effort.** At `high`, this prompt burned 32768 tokens entirely on *thinking* and
  returned an empty answer. Use `medium`, `low` or `none` for code. `reasoning_budget_tokens`
  (in the request or in `strata-iq2_xs.json`) reserves room to answer — not yet configured.

## Remote access

Not exposed. To reach it from another machine, use an SSH tunnel:

```sh
ssh -N -L 8080:127.0.0.1:8080 dperique@<this-machine>
```

If exposing it instead, `--host 0.0.0.0` must **only** be used together with `--api-key`.
