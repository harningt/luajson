#!/usr/bin/env bash
set -euo pipefail

# Print usage if requested
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    echo "Usage: $0 [lua_version] [lpeg_version] [luarocks_version]"
    echo "Examples:"
    echo "  $0 \"lua 5.3\" \"1.0.1-1\""
    echo "  $0 \"luajit 2.1\" \"1.1.0-1\""
    echo "  $0 \"lua 5.4\" \"1.1.0-1\""
    exit 0
fi

LUA_VER=${1:-"lua 5.3"}
LPEG_VER=${2:-"1.0.1-1"}
LUAROCKS_VER=${3:-"latest"}

# Normalize naming for folder name
LUA_DIR_NAME=$(echo "$LUA_VER" | tr -d '[:space:]')
ENV_DIR=".hererocks/${LUA_DIR_NAME}-lpeg${LPEG_VER}"

echo "======================================"
echo "Setting up / running test environment"
echo "Lua version:      $LUA_VER"
echo "LPeg version:     $LPEG_VER"
echo "LuaRocks version: $LUAROCKS_VER"
echo "Target directory: $ENV_DIR"
echo "======================================"

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# 1. Setup Python virtual environment for hererocks
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment for hererocks..."
    python3 -m venv .venv
fi

# Activate python virtual environment
source .venv/bin/activate

# Install hererocks in .venv if not installed
if ! command -v hererocks &> /dev/null; then
    echo "Installing hererocks in virtual environment..."
    pip install --upgrade pip
    pip install git+https://github.com/luarocks/hererocks
fi

# 2. Build/Validate hererocks environment
if [ ! -d "$ENV_DIR" ]; then
    echo "Building hererocks environment for $LUA_VER..."

    # Parse LUA_VER to construct the correct hererocks flag
    if [[ "$LUA_VER" =~ ^[Ll]ua[Jj]it ]]; then
        VERSION_PART=$(echo "$LUA_VER" | sed -E 's/^[Ll]ua[Jj]it[[:space:]]*//')
        LUA_FLAG="--luajit $VERSION_PART"
    elif [[ "$LUA_VER" =~ ^[Mm]oon[Jj]it ]]; then
        VERSION_PART=$(echo "$LUA_VER" | sed -E 's/^[Mm]oon[Jj]it[[:space:]]*//')
        LUA_FLAG="--moonjit $VERSION_PART"
    else
        VERSION_PART=$(echo "$LUA_VER" | sed -E 's/^[Ll]ua[[:space:]]*//')
        LUA_FLAG="--lua $VERSION_PART"
    fi

    hererocks "$ENV_DIR" -r "$LUAROCKS_VER" $LUA_FLAG --no-readline

    # Activate hererocks environment to install dependencies
    source "$ENV_DIR/bin/activate"

    echo "Installing test dependencies via direct LuaRocks URLs..."
    luarocks install https://luarocks.org/datafile-0.11-1.src.rock
    luarocks install https://luarocks.org/luacov-0.17.0-1.src.rock
    luarocks install https://luarocks.org/lunitx-0.8-2.src.rock
    luarocks install https://luarocks.org/luafilesystem-1.9.0-1.src.rock
    luarocks install "https://luarocks.org/lpeg-${LPEG_VER}.src.rock"
else
    # Activate existing hererocks environment
    source "$ENV_DIR/bin/activate"
fi

# 3. Run the tests
echo "Running tests in the target environment..."
# Clean up any residual coverage file from previous runs
rm -f tests/luacov.stats.out

# In the test suite, Makefile sets LUA_SETUP to override LUA_INIT with hook_require.lua.
# We pass LUA_BIN=lua, LUNIT_BIN=lunit.sh, and inject LUA_INIT with luarocks loader and luacov.
make LUA_BIN=lua LUNIT_BIN=lunit.sh LUA_INIT="require('luarocks.loader');require('luacov')" check

echo "Tests completed successfully."
