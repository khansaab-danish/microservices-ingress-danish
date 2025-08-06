#!/bin/bash

# Create README file
echo "# microservices-ingress-danish" >> README.md

# Initialize Git repository
git init

# Stage README
git add README.md

# Commit changes
git commit -m "first commit"

# Rename branch to main
git branch -M main

# Add remote repository
git remote add origin https://github.com/khansaab-danish/microservices-ingress-danish.git

# Push to GitHub
git push -u origin main

# Repeat commands as per your request
git remote add origin https://github.com/khansaab-danish/microservices-ingress-danish.git
git branch -M main
git push -u origin main
