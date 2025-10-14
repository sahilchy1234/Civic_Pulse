#!/bin/bash

echo ""
echo "============================================"
echo "  CivicSense Admin Panel - Quick Start"
echo "============================================"
echo ""

# Check if Python is available
if command -v python3 &> /dev/null; then
    echo "Starting local server on http://localhost:8000"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""
    python3 -m http.server 8000
elif command -v python &> /dev/null; then
    echo "Starting local server on http://localhost:8000"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""
    python -m SimpleHTTPServer 8000
else
    echo "Python not found. Opening index.html directly..."
    echo ""
    
    # Try to open in default browser
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open index.html
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        xdg-open index.html
    else
        echo "Please open index.html in your web browser"
    fi
fi

