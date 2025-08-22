#!/bin/bash

echo "🃏 Poker Odds Calculator - Setup Script"
echo "======================================"
echo ""

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install it first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    exit 1
fi

echo "✅ Homebrew found"

# Check for opam
if ! command -v opam &> /dev/null; then
    echo "📦 Installing opam (OCaml package manager)..."
    brew install opam
    
    echo "🔧 Initializing opam..."
    opam init -y
    eval $(opam env)
else
    echo "✅ opam found"
    eval $(opam env)
fi

# Install OCaml if needed
echo "🐫 Setting up OCaml 4.14..."
opam switch create 4.14.1 2>/dev/null || opam switch 4.14.1
eval $(opam env)

# Install required packages
echo "📚 Installing required OCaml packages..."
opam install -y dune graphics

echo ""
echo "✨ Setup complete!"
echo ""
echo "To build and run the project:"
echo "  eval \$(opam env)"
echo "  dune build"
echo "  dune exec poker_odds_calculator"
echo ""
echo "Or simply run: ./run.sh" 