# v0.1.0 release notes

## What this release is

This is the first public release of `transcription-server`, a small deployment wrapper around `hwdsl2/docker-whisper` for running local speech-to-text on a Raspberry Pi or small Linux host.

I built it for a very specific reason. I wanted OpenClaw to handle voice notes without making the main workstation miserable to use. Running Whisper on the same machine as an active OpenClaw setup was CPU-heavy enough that one transcription job could drag everything else down with it. Moving transcription onto a separate box fixed the problem.

That is the whole idea here. Keep transcription nearby, keep it self-hosted, and keep the operational surface small.

## What is in v0.1.0

- tracked default binding to `127.0.0.1`
- host-specific overrides through gitignored `.env`
- runtime settings and secrets kept in gitignored `whisper.env`
- simple remote deploy flow with `rsync` and `ssh`
- helper scripts for restart, status, and logs
- pinned upstream container image for reproducible deploys
- MIT license
- rewritten README with clearer setup, architecture, and scope

## Good fit

This repo makes sense if you want:

- self-hosted STT on a Pi or small Linux box
- a local transcription endpoint for agents, bots, or scripts
- a tiny repo you can inspect quickly and bend to your own setup

## Not the point of this repo

This is not:

- a new ASR model
- a hosted SaaS product
- a public-Internet-hardened deployment stack
- a replacement for the upstream server project

If all you need is the server itself, start with the upstream repo.

## Upgrade notes

If you were using the earlier private setup, the main repo-facing changes are:

- tracked defaults now bind to localhost instead of all interfaces
- machine-specific deployment details belong in `.env`
- runtime secrets and model config belong in `whisper.env`

If you still want LAN-visible access, set `WHISPER_BIND_ADDR=0.0.0.0` in your private `.env`.

## Credit

The core server work is upstream in [`hwdsl2/docker-whisper`](https://github.com/hwdsl2/docker-whisper). This repo is the deployment wrapper and local-tool integration layer around that work.
