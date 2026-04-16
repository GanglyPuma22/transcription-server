# v0.1.0 launch copy drafts

Image to attach with LinkedIn and X post:
- `docs/architecture-diagram.png`

## GitHub release blurb

`transcription-server` is a small self-hosted transcription box for local tools.

I built it after running into a pretty simple problem: Whisper was useful, but running it on the same machine as an active OpenClaw setup was enough to make everything else feel slow. So I moved transcription onto a Raspberry Pi and wrapped the deploy, restart, logs, and status story into a tiny repo.

It is intentionally thin. The model work is upstream in `hwdsl2/docker-whisper`. This repo is the part that made it pleasant to actually live with in a local-agent workflow.

## LinkedIn draft

A pattern I keep coming back to with OpenClaw is this: build around a real problem, keep the fix small, and ship the parts that might be useful to other people too.

This repo started from a pretty specific pain point. I wanted OpenClaw to handle voice notes as part of a local-agent workflow, but running Whisper on the same workstation as the agent stack was too CPU-heavy. One transcription job could make the rest of the system feel sluggish.

So I split that responsibility out. `transcription-server` is the small repo that came out of it: a self-hosted transcription box for a Raspberry Pi or small Linux host, with safe defaults, a simple deploy path, and a clean handoff back into the agent workflow.

It is not a new speech-to-text model, and that is not the claim. The useful part is taking solid upstream OSS, packaging it carefully, and making it practical inside a system I actually use.

That is the broader thread I care about with OpenClaw too: not just agents for the sake of agents, but small, inspectable tools around them that make the whole system more useful.

Repo: <add-url>
Attach image: `docs/architecture-diagram.png`

## X draft

A pattern I keep coming back to with OpenClaw:
build for a real workflow, keep the fix small, ship the useful part.

Latest example: `transcription-server`.

I wanted voice-note handling in a local-agent setup, but running Whisper on the same box as OpenClaw was enough to make active sessions crawl. So I moved transcription onto a Pi and wrapped the deploy/restart/logs/status story into a tiny repo.

Not a new ASR model. Just a practical self-hosted transcription box for local agents and scripts.

Repo: <add-url>
Attach image: `docs/architecture-diagram.png`

## Short Discord / forum draft

I just open-sourced a small transcription box I use with OpenClaw and other local tools.

The reason was simple: running Whisper on the same machine as the agent stack was enough to slow everything down. This repo moves transcription onto a Pi or small Linux host and keeps the deploy story simple.

It is basically the ops layer around `docker-whisper`, packaged in a way that is easy to inspect, fork, and use in local-agent workflows.

Repo: <add-url>
