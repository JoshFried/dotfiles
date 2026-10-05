#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="${1:-$repo_root/CHEATSHEETS.pdf}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

for dependency in pandoc xelatex pdfunite; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$dependency" >&2
        exit 1
    fi
done

common_args=(
    --pdf-engine=xelatex
    --from=gfm
    --standalone
    --metadata=title:"Dotfiles Keyboard and Workflow Cheat Sheets"
    --variable=documentclass:extarticle
    --variable=mainfont:"Helvetica Neue"
    --variable=monofont:"Menlo"
    --variable=colorlinks:false
    --variable=papersize:letter
)

pandoc \
    "$repo_root/WORKFLOW_CHEATSHEET.md" \
    "$repo_root/macos/.hammerspoon/CHEATSHEET.md" \
    "${common_args[@]}" \
    --variable=fontsize:9pt \
    --variable=classoption:twocolumn \
    --variable=geometry:"margin=0.55in" \
    --output="$tmp_dir/workflow.pdf"

pandoc \
    "$repo_root/DACTYL_CHEATSHEET.md" \
    "${common_args[@]}" \
    --variable=fontsize:8pt \
    --variable=classoption:landscape \
    --variable=geometry:"margin=0.3in" \
    --output="$tmp_dir/dactyl.pdf"

pdfunite "$tmp_dir/workflow.pdf" "$tmp_dir/dactyl.pdf" "$output"
printf 'Wrote %s\n' "$output"
