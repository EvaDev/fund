#!/bin/bash

echo "Setting up Fund Management UI..."

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo "pnpm not found. Installing pnpm..."
    npm install -g pnpm
fi

# Install dependencies
echo "Installing dependencies..."
pnpm install

# Install Tailwind CSS
echo "Installing Tailwind CSS..."
cd shared && pnpm add -D tailwindcss postcss autoprefixer
cd ../fund-manager-app && pnpm add -D tailwindcss postcss autoprefixer
cd ../beneficiary-app && pnpm add -D tailwindcss postcss autoprefixer

echo "Setup complete!"
echo ""
echo "To start the apps:"
echo "  Fund Manager App: cd fund-manager-app && pnpm start"
echo "  Beneficiary App: cd beneficiary-app && pnpm start"
echo ""
echo "Apps will be available at:"
echo "  Fund Manager: http://localhost:3001"
echo "  Beneficiary: http://localhost:3002"
