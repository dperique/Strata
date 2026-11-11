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
cmake --build build --target strata -j8
./start.sh
./status.sh
```

Keep `strata-iq2_xs.json` and its settings. Do not run `setup.sh` with only one custom option;
setup can reset options that were not repeated.

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
