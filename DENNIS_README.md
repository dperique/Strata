# Dennis's Strata fork

This checkout uses two Git remotes:

```text
origin   git@github.com:dperique/Strata.git       # my fork
upstream https://github.com/Niko1221/Strata       # original repository
```

My changes are on the public fork branch:

```text
dennis_kpc2_strata
```

The known-good checkout before moving to the fork was commit `296b59d2f73c8f04a805df29c2fa97655adace78`,
tagged `v0.1.44.1`. That is the baseline to return to if the newer upstream build causes trouble.

The branch contains `MY-SETUP.md`, `start.sh`, `status.sh`, and `stop.sh`.

## Sync this branch with upstream

From the repository directory:

```sh
git fetch upstream
git switch dennis_kpc2_strata
git rebase upstream/main
git push --force-with-lease origin dennis_kpc2_strata
```

The force-with-lease is needed because rebase changes the branch history. It protects against
overwriting a newer branch update that was pushed by someone else.

To see the remotes and branch tracking:

```sh
git remote -v
git branch -vv
```

Keep `main` for upstream reference; it tracks `upstream/main`. Do new work on
`dennis_kpc2_strata` or another topic branch, not directly on `main`.

## Rebuild after upstream changes

The running server and the compiled CUDA engine do not change just because Git changes. After
rebasing onto upstream, stop the old server, rebuild the existing CUDA build, then start again:

```sh
./stop.sh
.venv/bin/cmake --build build --target strata -j8
cp build/strata engine/strata
./start.sh
./status.sh
```

On this machine, system `cmake` is not on `PATH`; the checkout's `.venv/bin/cmake` works.
The existing `build/` directory is the configured CUDA/Ninja build for the RTX 4090
(`CMAKE_CUDA_ARCHITECTURES=89`). Reusing it avoids changing the working model setup. The build
places the new executable at `build/strata`, while `strata-iq2_xs.json` starts `engine/strata`,
so the copy step is required. Check that both files have the same SHA-256 after copying.

Keep `strata-iq2_xs.json` and its settings. Do not run `setup.sh` with only one custom option;
setup can reset options that were not repeated.

Run `./stop.sh` as its own command. Do not append a `pgrep -f` check whose search text contains
`server.py --engine` or `engine/strata` to the same shell command: `pgrep` can see the wrapper
command itself and report or signal that extra PID. If the stop command reports exit 143, check
`curl -s http://127.0.0.1:8080/health` separately before retrying; the real server may already be
stopped.

The startup smoke test needs enough output room for reasoning. The checked-in `start.sh` uses
`max_tokens: 64`; with 16 tokens the model can spend the whole budget thinking and return no final
content even though the server is healthy. Confirm with `./status.sh` and, if needed, a direct
request with `max_tokens` 64 or more.

The current known-good rebuilt engine from upstream base `6c642df7` has SHA-256
`d26e4049011fc0962a0d3ba2eded17ae35ae6b7befbdd359ac4ba976627aecb8`.

## What is not committed

These local files were intentionally left out of the public fork:

```text
strata-iq2_xs.json.bak
strata-iq2_xs.json.bak-2026-10-17
strata-server.out
```

The backups contain machine-specific absolute paths. The log contains local runtime details.

## Public-repository check

The committed helper files contain no API keys, passwords, tokens, private keys, or bearer
credentials. The server commands use `127.0.0.1`, so they do not expose the service by default.
The setup notes do reveal the local username, checkout path, hardware, driver version, and model
configuration. That is personal information, but it is not an access credential. The scripts also
contain Dennis's absolute checkout path, so they are intended for this machine rather than as
portable generic setup scripts.
