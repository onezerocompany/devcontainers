#!/bin/bash
# Install apt-fast for parallel package downloads
set -e

echo "📦 Installing package manager optimizations..."

# Create necessary directories
mkdir -p /etc/bash_completion.d

# Download and install apt-fast for parallel package downloads
wget -O /usr/local/sbin/apt-fast "https://raw.githubusercontent.com/ilikenwf/apt-fast/master/apt-fast"
chmod +x /usr/local/sbin/apt-fast
wget -O /etc/bash_completion.d/apt-fast "https://raw.githubusercontent.com/ilikenwf/apt-fast/master/completions/bash/apt-fast"

# Configure apt-fast with optimized settings
cat > /etc/apt-fast.conf << 'EOF'
# apt-fast configuration for parallel downloads
_APTMGR=apt-get
DOWNLOADBEFORE=true
_MAXNUM=5
_MAXCONPERSRV=10
_SPLITCON=8
_MINSPLITSZ=1M
_PIECEALGO=default
DLLIST='/tmp/apt-fast.list'
_DOWNLOADER='aria2c --no-conf -c -j ${_MAXNUM} -x ${_MAXCONPERSRV} -s ${_SPLITCON} -i ${DLLIST} --min-split-size=${_MINSPLITSZ} --stream-piece-selector=${_PIECEALGO} --connect-timeout=60 --timeout=600 --max-connection-per-server=16'
APTCACHE=/var/cache/apt/apt-fast
EOF

# Install aria2 (required for apt-fast parallel downloads)
apt-get install -y aria2
echo "  ✅ apt-fast installed successfully."