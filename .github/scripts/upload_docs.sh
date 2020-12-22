#!/usr/bin/env sh

git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
cd "${DOCS_PATH}"
git init
git remote add origin $GIT_REPO
git fetch origin
git reset origin/gh-pages
git add -A .
git commit --allow-empty -m "Updating documents"
git push origin HEAD:gh-pages
