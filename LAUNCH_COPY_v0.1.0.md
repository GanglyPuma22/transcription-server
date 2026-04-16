# v0.1.0 launch copy drafts

## GitHub release blurb

`transcription-server` is a small self-hosted transcription box for local tools.

I built it after running into a pretty simple problem: Whisper was useful, but running it on the same machine as an active OpenClaw setup was enough to make everything else feel slow. So I moved transcription onto a Raspberry Pi and wrapped the deploy, restart, logs, and status story into a tiny repo.

It is intentionally thin. The model work is upstream in `hwdsl2/docker-whisper`. This repo is the part that made it pleasant to actually live with in a local-agent workflow.

## LinkedIn draft

One pattern I keep coming back to with OpenClaw is this: build a tool to solve a real problem in my own workflow, then clean it up enough that other people might actually want it too.

This one started because I wanted OpenClaw to handle voice notes without dragging down the main machine. Running Whisper on the same workstation as an active agent setup was too CPU-heavy. One transcription job could make the rest of the system feel sticky.

So I split that responsibility out. `transcription-server` is the small repo that came out of it: a self-hosted transcription box for a Raspberry Pi or small Linux host, with sane defaults and a simple deploy story.

It is not a new speech-to-text model. That is not the claim. The useful part is taking solid upstream OSS, packaging it carefully, and making it work well inside a real local-agent system.

That is probably the broader thread I care about most right now: building around agents in a way that stays practical, inspectable, and worth shipping.

Repo: <add-url>

## X draft

A pattern I keep coming back to with OpenClaw: build a tool for my own workflow, then clean it up enough to ship.

Latest example: `transcription-server`.

I built it after realizing local Whisper on my main OpenClaw box was enough to make active sessions crawl. So I moved transcription onto a Pi and wrapped the deploy/restart/logs/status story into a tiny repo.

Not a new ASR model. Just a practical self-hosted transcription box for local agents and scripts.

Repo: <add-url>

## Short Discord / forum draft

I just open-sourced a small transcription box I use with OpenClaw and other local tools.

The reason was simple: running Whisper on the same machine as the agent stack was enough to slow everything down. This repo moves transcription onto a Pi or small Linux host and keeps the deploy story simple.

It is basically the ops layer around `docker-whisper`, packaged in a way that is easy to inspect, fork, and use in local-agent workflows.

Repo: <add-url>
