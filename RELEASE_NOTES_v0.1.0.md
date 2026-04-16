# v0.1.0 release notes

## What this release is

This is the first public-shaped release of `transcription-server`: a small deployment wrapper around `hwdsl2/docker-whisper` for running local speech-to-text on a Raspberry Pi or small Linux host.

The point is not to reinvent Whisper. The point is to make self-hosted transcription easy to deploy, easy to reason about, and easy to plug into local tools such as OpenClaw.

## Highlights

- safe tracked default network binding to `127.0.0.1`
- host-specific overrides via gitignored `.env`
- runtime settings kept in gitignored `whisper.env`
- simple remote deploy flow with `rsync` + `ssh`
- remote restart, status, and logs helper scripts
- pinned upstream container image for reproducible deploys
- MIT license and a README shaped for real users, not just the repo owner

## Why it exists

This repo came out of a practical problem: running Whisper on the same machine as an active OpenClaw setup was CPU-heavy enough to slow down other work. Moving transcription onto a separate Pi kept the local-agent workflow intact without turning the main box into sludge.

## Good fit

Use this if you want:

- self-hosted STT on a Pi or small Linux box
- a local transcription endpoint for agents, bots, or scripts
- a tiny repo you can inspect and fork quickly

## Not the point of this repo

This is not:

- a new ASR model
- a hosted SaaS
- a public-Internet-hardened deployment stack
- a replacement for the upstream server project

## Upgrade notes

If you were using the earlier private setup, the main repo-facing changes are:

- tracked defaults now bind to localhost instead of all interfaces
- machine-specific deployment details should live in `.env`
- runtime secrets and model config stay in `whisper.env`

If you still want LAN-visible access, set `WHISPER_BIND_ADDR=0.0.0.0` in your private `.env`.

## Credits

Core server work is upstream in [`hwdsl2/docker-whisper`](https://github.com/hwdsl2/docker-whisper). This repo is the deployment wrapper and integration-oriented operational layer around that work.
