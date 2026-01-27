#!/bin/bash
# Update Hugo to latest version
set -e

LATEST=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
VERSION=${LATEST#v}

echo "Latest Hugo version: $VERSION"
echo "Current version: $(hugo version | grep -oP 'v\d+\.\d+\.\d+')"

read -p "Download and install? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd /tmp
    curl -sLO "https://github.com/gohugoio/hugo/releases/download/${LATEST}/hugo_extended_${VERSION}_linux-amd64.deb"
    sudo dpkg -i "hugo_extended_${VERSION}_linux-amd64.deb"
    echo "Installed: $(hugo version)"
fi
