#!/bin/bash

echo "🃏 Running Poker Odds Calculator..."
echo ""

# Setup opam environment
if command -v opam &> /dev/null; then
    eval $(opam env)
fi

# Build the project
echo "🔨 Building..."
if dune build; then
    echo "✅ Build successful!"
    echo ""
    echo "🚀 Launching GUI..."
    dune exec poker_odds_calculator
else
    echo "❌ Build failed. Please run ./setup.sh first"
fi 