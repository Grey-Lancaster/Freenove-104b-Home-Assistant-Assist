# Papa Lanc Assist

ESPHome firmware turning a **Freenove FNK0104B** (ESP32-S3, 2.8" ILI9341
LCD, ES8311 audio codec) into a wake-word-activated Home Assistant
**Assist** satellite. Say "Hey Jarvis," then talk — no button, no app.

## Status

Working end-to-end: wake word → mic capture → STT → HA intent handling →
TTS → speaker playback, plus a live LCD screen (boot logo → "Listening..."
→ "You said / Response" → date & time footer). See
[CHANGELOG.md](CHANGELOG.md) for version history.

## Hardware

- ESP32-S3-WROOM-1-N16R8 (16MB flash, 8MB octal PSRAM)
- ES8311 codec: analog mic (ADC) + speaker (DAC) over one shared I2S bus,
  I2C-controlled
- 2.8" ILI9341 LCD (SPI, 240x320)
- WS2812 status LED (GPIO42)

## Voice pipeline

- **Wake word**: on-device `micro_wake_word` ("Hey Jarvis")
- **STT**: Whisper (`turbo` model), GPU-accelerated via a `faster-whisper`
  Wyoming server on a separate host on the LAN
- **TTS**: Piper (`en_US-lessac-medium`), local Wyoming server on the same
  host

Both STT and TTS run off-device — the ESP32 only handles wake-word
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

1. **Boot**: custom logo, cropped to content and centered
2. **Listening**: shown the moment the mic starts capturing after
   wake-word detection
3. **You said / Response**: live transcript and assistant reply,
   word-wrapped
4. All screens show a date/time footer synced from Home Assistant

## Known limits

- Wake-word pickup distance is limited by hardware — both the mic preamp
  gain and the software AGC are already at their maximum configurable
  values.
- Display is view-only; the board's FT6336U touch controller isn't wired
  in yet.
