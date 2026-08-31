# Changelog

All notable changes to this project are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/).

## [0.5.16] - 2026-08-31

### Added
- Tap-to-listen: the FT6336U touch controller (already present on the
  I2C bus at 0x38, previously unused) now triggers `voice_assistant.start`
  on any touch, as a fallback for when the wake word doesn't cooperate.
  Confirmed in real use: a tap lets you speak at a normal tone with no
  wake-word struggle.

### Changed
- Wake-word `probability_cutoff` loosened further, 0.75 -> 0.65, now that
  touch provides a reliable fallback -- stops well above the VAD
  sub-model's own 0.50 threshold, which is a "might be speech" floor, not
  a confident wake-word match.

## [0.5.12] - 2026-08-31

### Changed
- Idle sensors screen now flips after 10s instead of 45s.
- Wake-word `probability_cutoff` loosened again, 0.80 -> 0.75, after
  real-world testing showed the first attempt after a fresh boot still
  took noticeable effort to trigger even at 0.80.

## [0.5.8] - 2026-08-31

### Added
- Idle sensors screen: after 45 seconds with nothing happening, the LCD
  flips from the boot logo / last text screen to three Home Assistant
  temperature sensors (office inside, office outside, big room), then
  refreshes every 5 minutes while it stays idle. Cancelled and reset
  around every real interaction so it can't fire mid-conversation.
  Each sensor is independently comment-out-able (see the matching
  `SENSOR-SCREEN` tags in both the `sensor:` block and the display
  `lambda:`); if all three are removed, the screen simply never flips
  and stays on the wake-word/boot screen instead.

### Investigating
- Found (not fixed here) a second dead-duplicate HA entity following the
  same pattern as the earlier orphaned `tplink` config entry:
  `sensor.office_outside_temp` is `unavailable` while
  `sensor.office_outside_temp_2` is the live one with real readings. Used
  the working `_2` entity; the dead one is still sitting in HA.

## [0.5.4] - 2026-08-31

### Added
- On-device wake word ("Hey Jarvis" via `micro_wake_word`) replacing
  push-to-talk entirely. Auto-restarts after every interaction (success or
  error), gated behind a `wait_until` so it doesn't race the speaker's I2S
  startup.
- 2.8" ILI9341 LCD: boot splash (custom logo, cropped to content and
  centered), a "Listening..." screen shown the moment the mic starts
  capturing, live "You said / Response" text with word-aware wrapping, and
  a Home-Assistant-synced date/time footer on every screen.
- Local STT (Whisper `turbo` model, GPU-accelerated via `faster-whisper` on
  a separate host) and local TTS (Piper, `en_US-lessac-medium`), replacing
  HA's unofficial Google Translate TTS engine, which turned out to be the
  root cause of wildly inconsistent response timing.
- `push-to-ha.sh`: fixed, single-command deploy script (uploads the YAML
  and logo to the Home Assistant host's ESPHome Dashboard config directory
  over SSH).

### Fixed
- ES8311 mic PDM/analog config bug — ESPHome's `es8311` component always
  enables PDM mode when `use_microphone: true`, but this board's mic is
  analog. Corrected with a raw I2C register write in `on_boot`.
- Mic capture reading the wrong I2S channel — ESPHome's `i2s_audio`
  microphone defaults to the RIGHT channel; this board's ES8311 only has
  real signal on the LEFT.
- `voice_assistant`'s `on_end` firing before TTS playback actually
  finishes, which raced the wake-word restart against the speaker's I2S
  startup (`Parent bus is busy`). Fixed with a `wait_until` gate matching
  ESPHome's own reference wake-word config.
- WiFi's periodic roaming scan interrupting live voice interactions —
  disabled (`post_connect_roaming: false`) since this is a stationary,
  plugged-in device.
- Boot-splash logo never actually reaching the display — `fill()`/`image()`
  only write into an in-memory buffer; the SPI flush to hardware only
  happens inside `update()`.
- Word-wrap bug that split words mid-character on the LCD text screen —
  replaced with word-aware wrapping.
- A ~200ms periodic full-screen SPI repaint (added for a live clock, then
  removed) that was very likely responsible for degraded wake-word
  reliability, since it ran during ordinary wake-word listening, not just
  during active conversations.

### Investigating
- Wake-word pickup distance is limited by hardware: both the ES8311 mic
  preamp (`mic_gain: 42DB`) and the software AGC (`auto_gain: 31dBFS`) are
  already at ESPHome's maximum allowed values, so further sensitivity would
  need a hardware change, not a config change.
