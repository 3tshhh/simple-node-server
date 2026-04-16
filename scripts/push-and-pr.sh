#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Ensure we're on dev
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "dev" ]; then
  echo -e "${RED}Error: You must be on the 'dev' branch. Currently on '${BRANCH}'.${NC}"
  exit 1
fi

# Check for changes
if [ -z "$(git status --porcelain)" ]; then
  echo -e "${RED}No changes to commit.${NC}"
  exit 1
fi

# Prompt for commit message
echo "Staged and unstaged changes:"
git status --short
echo ""
read -p "Commit message: " COMMIT_MSG

if [ -z "$COMMIT_MSG" ]; then
  echo -e "${RED}Commit message cannot be empty.${NC}"
  exit 1
fi

# Add, commit, push
git add -A
git commit -m "$COMMIT_MSG"
git push origin dev

# Check if a PR already exists for dev -> main
EXISTING_PR=$(gh pr list --head dev --base main --state open --json number --jq '.[0].number' 2>/dev/null || true)

if [ -n "$EXISTING_PR" ]; then
  echo ""
  echo -e "${YELLOW}PR #${EXISTING_PR} already exists — pushed new changes to it.${NC}"
  echo -e "${GREEN}CI will re-run automatically.${NC}"
else
  echo ""
  echo -e "${GREEN}Opening PR to main...${NC}"
  gh pr create --base main --head dev --title "$COMMIT_MSG" --fill
fi

echo -e "${GREEN}Done!${NC}"
