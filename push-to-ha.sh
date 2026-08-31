#!/bin/bash
set -e
scp -P 22 -i ~/.ssh/claude_ha_ed25519 -o ControlPath=none \
  "H:/Claude Local/Freenove104b_repo/assist-satellite/assist-satellite.yaml" \
  root@192.168.1.60:/config/esphome/papa-lanc-assist.yaml
scp -P 22 -i ~/.ssh/claude_ha_ed25519 -o ControlPath=none \
  "H:/Claude Local/Freenove104b_repo/assist-satellite/images/grey_fox_logo.png" \
  root@192.168.1.60:/config/esphome/images/grey_fox_logo.png
echo "Pushed assist-satellite.yaml and grey_fox_logo.png to HA host."
