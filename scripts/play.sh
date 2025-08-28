#!/usr/bin/env bash
cd "$HOME/OneDrive/Documents/GroundNode"
if [ -f .venv/Scripts/activate ]; then
  source .venv/Scripts/activate
else
  echo "activate not found"; read -p "Enter to close"; exit 1
fi
echo "Play ready"
exec bash -i
