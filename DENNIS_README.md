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
