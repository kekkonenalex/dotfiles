#!/usr/bin/env bash
# Symlinks every folder under claude/skills into ~/.claude/skills.
set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills_src_dir="$dotfiles/claude/skills"
skills_dest_dir="$HOME/.claude/skills"

mkdir -p "$skills_dest_dir"

for src in "$skills_src_dir"/*/; do
    name="$(basename "$src")"
    link="$skills_dest_dir/$name"

    if [ -e "$link" ] || [ -L "$link" ]; then
        if [ -L "$link" ] && [ "$(readlink "$link")" = "${src%/}" ]; then
            echo "OK (already linked): $name"
            continue
        fi
        echo "SKIP (exists, not our symlink): $name -- remove it manually if you want to relink"
        continue
    fi

    ln -s "${src%/}" "$link"
    echo "linked $name"
done
