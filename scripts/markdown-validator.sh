#!/bin/bash

# Check Markdown formating of all the "*.md" files that are changed and commited to the current branch.
#
# Usage:
#   $ [options] ./markdown-check-format.sh
#
# Options:
#   BRANCH_NAME=other-branch-than-main  # Branch to compare with

# Please, make sure to enable Markdown linting in your IDE. For the Visual Studio Code editor it is
# `davidanson.vscode-markdownlint` that is already specified in the `.vscode/extensions.json` file.

files=$((git diff --diff-filter=ACMRT --name-only origin/${BRANCH_NAME:-main}.. "*.md"; git diff --name-only "*.md") | sort | uniq)
#files=$((find . -name "*.md" -printf '%P\n') | sort | uniq)

if [ -n "$files" ]; then
  image=ghcr.io/igorshubovych/markdownlint-cli@sha256:b771097d3d9ec6b368fefcea5f0c05c8710293d9251fca17e31c8e10987b50ef # v0.46.0
  docker run --rm \
    -v $PWD:/workdir \
    $image \
      $files \
      --disable MD013 MD033 MD060 # MD060 disabled until VS Code support is available
fi