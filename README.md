# Papa Lanc Assist

ESPHome firmware turning a **Freenove FNK0104B** (ESP32-S3, 2.8" ILI9341
LCD, ES8311 audio codec) into a Home Assistant **Assist** satellite. Say
"Hey Jarvis" and talk, or just tap the screen — no button, no app.

## Status

Working end-to-end: wake word (or a tap) → mic capture → STT → HA intent
handling → TTS → speaker playback, plus a live LCD screen (boot logo →
"Listening..." → "You said / Response" → idle sensors screen). See
[CHANGELOG.md](CHANGELOG.md) for version history.

## Hardware

- ESP32-S3-WROOM-1-N16R8 (16MB flash, 8MB **octal** PSRAM)
- ES8311 codec: analog mic (ADC) + speaker (DAC) over one shared I2S bus,
  I2C-controlled
- 2.8" ILI9341 LCD (SPI, 240x320)
- FT6336U capacitive touch controller (I2C, shares the bus with the ES8311
  codec — I2C is a multi-device bus by design, so this is a normal,
  low-risk pairing, unlike the I2S full-duplex conflicts documented
  elsewhere in this project)
- WS2812 status LED (GPIO42)

**Why `psram: speed: 80MHz` is set explicitly**: the "N16R8" suffix on this
module's part number means its PSRAM chip is wired in **octal**-SPI mode
(8 data lines), not the more common quad-SPI (4 lines). Octal PSRAM is
electrically rated for faster clocking, so ESPHome allows 80MHz here where
a quad-PSRAM board would typically be capped lower (its default, if
unspecified, is 40MHz). The next step up, 120MHz, exists but is flagged
"experimental" in octal mode and separately requires bumping the CPU to
240MHz, so 80MHz is the highest speed here that's both fully supported and
free of extra CPU/stability tradeoffs — chosen for headroom on the
display's larger draw buffers and the audio pipeline's ring buffers, not
because it was the max the hardware could ever theoretically do.

## Interaction

- **Wake word**: on-device `micro_wake_word` ("Hey Jarvis") — cutoff tuned
  down from the 0.97 default to 0.50 after real-world testing (including
  live TV audio) showed no false positives even at that level. A
  companion VAD model (cutoff 0.40) has to agree it's hearing speech
  before a detection counts.
- **Touch**: tapping anywhere on the screen starts listening immediately,
  as a fallback for whenever the wake word doesn't cooperate. Guarded the
  same way as the automatic wake-word restart (waits for the previous
  session's speaker to finish, not just for the pipeline to end) so a tap
  can't race a still-finishing interaction.

## Voice pipeline

- **STT**: Whisper (`turbo` model), GPU-accelerated via a `faster-whisper`
  Wyoming server on a separate host on the LAN
- **TTS**: Piper (`en_US-lessac-medium`), local Wyoming server on the same
  host

Both STT and TTS run off-device — the ESP32 only handles wake-word/touch
detection, audio streaming, and display.

## Deploying changes

The actual build happens through Home Assistant's **ESPHome Dashboard**
add-on, not the standalone `esphome` CLI. `assist-satellite.yaml` in this
repo is the source of truth; push it to the HA host's
`/config/esphome/` directory with:

```bash
./push-to-ha.sh
```

Then trigger a build/install from the ESPHome Dashboard in HA.

`secrets.yaml` (WiFi credentials, API encryption key) is intentionally
gitignored — copy `secrets.yaml.example` and fill in your own values before
building.

## LCD screens

1. **Boot**: custom logo, cropped to content and centered. Shows the
   device's current IP address in the footer (not the clock) — an empty
   value here means WiFi hasn't connected.
2. **Listening**: shown the moment the mic starts capturing after a wake
   word or a tap
3. **You said / Response**: live transcript and assistant reply,
   word-wrapped, with a date/time footer synced from Home Assistant
4. **Sensors**: after 10s idle, flips to office inside/outside and
   big-room temperatures (pulled live from HA), refreshing every 5
   minutes. Each sensor is independently comment-out-able in the YAML
   (see the matching `SENSOR-SCREEN` tags); if all three are removed, this
   screen just never appears.

## Known limits

- Wake-word pickup distance is limited by hardware — both the mic preamp
  gain and the software AGC are already at their maximum configurable
  values. Touch is the fallback for when this matters.
