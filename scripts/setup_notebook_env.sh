#!/usr/bin/env bash
set -e

PYTHON="${PYTHON:-python3.11}"

if ! command -v "$PYTHON" >/dev/null 2>&1; then
    echo "Error: $PYTHON not found. The pinned requirements need Python 3.10, 3.11 or 3.12."
    echo "Install Python 3.11 (see the setup guide), or choose another version with e.g. PYTHON=python3.10"
    exit 1
fi

if ! "$PYTHON" -c 'import sys; sys.exit(0 if (3, 10) <= sys.version_info[:2] <= (3, 12) else 1)'; then
    echo "Error: $PYTHON is $("$PYTHON" -V 2>&1), but the pinned requirements need Python 3.10, 3.11 or 3.12."
    exit 1
fi

echo "Creating Python virtual environment with $("$PYTHON" -V)..."
"$PYTHON" -m venv .venv

echo "Activating virtual environment..."
source .venv/bin/activate

echo "Upgrading pip..."
python -m pip install --upgrade pip wheel "setuptools<70"

echo "Installing requirements..."
pip install -r requirements.txt

echo "Installing Jupyter kernel..."
python -m ipykernel install --user --name seavea-notebooks --display-name "SEAVEA Notebooks"

echo "Setup complete."
echo "To activate the environment later, run:"
echo "source .venv/bin/activate"
