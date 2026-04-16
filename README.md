# transcription-server

Minimal Dockerized Whisper transcription server for the Raspberry Pi host `video-server`.

## Current production settings
- Image: `hwdsl2/whisper-server@sha256:94dc52fe65de35d20cf1e14be9805c471552e28aba1b71b582d7d685106850c4`
- Model: `base.en`
- Language: `en`
- Device: CPU / INT8
- Port: `9000`
- Restart policy: `unless-stopped`

## Why this repo exists
The Pi service was initially created ad hoc under `~/services/whisper`.
This app folder is the traceable source of truth so future updates can be committed, reviewed, and redeployed cleanly.

## Local files
- `docker-compose.yml` — pinned deployment config
- `whisper.env.example` — template only; real `whisper.env` stays on the Pi and is gitignored
- `scripts/sync-to-pi.sh` — rsync app files to the Pi
- `scripts/deploy-to-pi.sh` — sync + ensure env + restart service from this app directory
- `scripts/restart-on-pi.sh` — clean container restart
- `scripts/status-on-pi.sh` — show compose status + restart policy
- `scripts/logs-on-pi.sh` — tail recent logs

## Deploy / update flow
From the workspace:

```bash
./apps/transcription-server/scripts/deploy-to-pi.sh
```

What it does:
1. rsyncs this app folder to `video-server:/home/mmounier/services/transcription-server`
2. reuses the existing `whisper.env` from the legacy `~/services/whisper` dir if present
3. stops the legacy compose stack if it exists
4. starts the service from the new `transcription-server` directory

## Routine management
Check status:

```bash
./apps/transcription-server/scripts/status-on-pi.sh
```

Clean restart after config/image changes:

```bash
./apps/transcription-server/scripts/restart-on-pi.sh
```

Show recent logs:

```bash
./apps/transcription-server/scripts/logs-on-pi.sh
```

## Restart behavior on Pi reboot/failure
This is currently **Docker Compose + Docker restart policy**, not a Swarm service and not a separate systemd unit.

Meaning:
- `docker compose up -d` creates the container
- Docker keeps it on `restart: unless-stopped`
- if the Pi reboots and Docker comes back, the container should come back automatically
- if the container crashes, Docker should restart it automatically

## Notes
- The model cache volume is pinned to `whisper_whisper-data` so redeploys reuse the already-downloaded model.
- Audio noise-cleaning experiments were intentionally removed from the service path; the default path is raw audio -> Pi `base.en`.
