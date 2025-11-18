#!/bin/bash

echo "🚀 Setting up GitHub remote..."
echo ""
echo "First, create a repository on GitHub:"
echo "1. Go to https://github.com/new"
echo "2. Repository name: fluentfly-ai (or your choice)"
echo "3. Make it PRIVATE (important!)"
echo "4. DON'T initialize with README"
echo "5. Click 'Create repository'"
echo ""
read -p "Have you created the repository? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please create the repository first, then run this script again."
    exit 1
fi

echo ""
echo "Enter your GitHub username:"
read github_username

echo ""
echo "Enter your repository name (e.g., fluentfly-ai):"
read repo_name

echo ""
echo "Setting up remote..."

# Add remote
git remote add origin "https://github.com/$github_username/$repo_name.git"

# Verify
echo ""
echo "✅ Remote added successfully!"
echo ""
echo "Remote URL: https://github.com/$github_username/$repo_name.git"
echo ""
echo "Now run these commands:"
echo ""
echo "1. Clean up unwanted files:"
echo "   ./cleanup-git.sh"
echo ""
echo "2. Add and commit changes:"
echo "   git add .gitignore"
echo "   git commit -m 'chore: Clean repository and add .gitignore'"
echo ""
echo "3. Push to GitHub:"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
