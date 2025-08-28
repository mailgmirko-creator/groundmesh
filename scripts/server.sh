#!/usr/bin/env bash
cd "$HOME/OneDrive/Documents/GroundNode"
source .venv/Scripts/activate || { echo "activate failed"; read -p "Enter"; exit 1; }
python agents/server/server.py
