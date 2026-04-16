# v0.1.0 launch copy drafts

## GitHub release blurb

`transcription-server` is a small self-hosted transcription box for local tools.

I built it because running Whisper on the same machine as an active OpenClaw setup was enough to make everything else sluggish. This repo moves transcription onto a separate Pi or Linux box and packages the day-2 ops around it: deploy, restart, logs, status, and safe tracked defaults.

It is intentionally thin. The core server work is upstream in `hwdsl2/docker-whisper`; this repo is the deployment wrapper around that.

## LinkedIn draft

I open-sourced a small thing I actually needed: a self-hosted transcription box for local tools.

The problem was simple. Running Whisper on the same machine as my active OpenClaw setup was CPU-heavy enough that one transcription job could slow down everything else. So I moved transcription onto a Raspberry Pi and wrapped the deployment into a tiny repo with sane defaults, remote deploy scripts, and a predictable local endpoint.

It is not a new speech-to-text model, and I am not pretending it is. The interesting part is the operational layer: taking upstream OSS, packaging it cleanly, and making it useful in a real workflow.

One example use case: an OpenClaw agent receives a Telegram voice note, sends it to the Pi, gets back text, and continues the workflow without relying on a hosted STT API.

Repo: <add-url>

## X draft

Open-sourced a small but useful piece of local AI infrastructure: `transcription-server`.

I built it after realizing local Whisper on my main OpenClaw box was enough to make active sessions crawl. So I moved transcription onto a Pi and wrapped the deploy/restart/logs/status workflow into a tiny repo with sane defaults.

Not a new ASR model. Just a clean operational wrapper around upstream OSS for local agents and scripts.

Repo: <add-url>

## Short Discord / forum draft

I open-sourced a small Raspberry Pi transcription wrapper I use for local tools and OpenClaw workflows.

It is basically the deployment and ops layer around `docker-whisper`: safe defaults, simple deploy scripts, and a clean local endpoint for agents or scripts that need STT without burning the main machine.

Repo: <add-url>
