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

# Make ~/.claude/CLAUDE.md import the shared claude/CLAUDE.md (same layout as on Windows,
# so the device file can also hold private, machine-only notes).
import_line="@~/dotfiles/claude/CLAUDE.md"
device_file="$HOME/.claude/CLAUDE.md"

if [ ! -e "$device_file" ]; then
    printf '%s\n\n# This device (private, not synced)\n\n- Describe this device here: personal or work laptop, OS, anything Claude should know only on this machine.\n' "$import_line" > "$device_file"
    echo "created $device_file (importing the shared CLAUDE.md)"
elif grep -qF "$import_line" "$device_file"; then
    echo "OK (already imports the shared CLAUDE.md): $device_file"
else
    cp "$device_file" "$device_file.prev"
    { printf '%s\n\n' "$import_line"; cat "$device_file.prev"; } > "$device_file"
    echo "added the import to the top of $device_file (old version saved as CLAUDE.md.prev)"
fi

# Install the Claude Code plugins listed in claude/plugins.txt. Both commands are no-ops when
# the marketplace or plugin is already there, so re-running the bootstrap is safe.
if ! command -v claude >/dev/null 2>&1; then
    echo "SKIP plugins: the claude CLI isn't on PATH. Install Claude Code, then re-run this script."
else
    while read -r plugin source _; do
        case "$plugin" in ''|'#'*) continue ;; esac
        if [ -n "${source:-}" ] && ! claude plugin marketplace add "$source" </dev/null >/dev/null; then
            echo "FAILED to add marketplace $source"
            continue
        fi
        if claude plugin install "$plugin" </dev/null >/dev/null; then
            echo "plugin ready: $plugin"
        else
            echo "FAILED to install plugin $plugin"
        fi
    done < "$dotfiles/claude/plugins.txt"
fi
