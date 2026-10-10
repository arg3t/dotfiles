#!/usr/bin/env bash
# .config/tern/plugins/workstreams/create.sh
#
# Invocation (via tern.process.run on the target host):
#   bash create.sh <cwd> <branch>
#
# Stdout on success: mode NUL checkout_path NUL branch NUL repo_root NUL.
# The mode is "overlay", "git", or "existing" for a matching checkout.
# Stderr reports errors and any partial checkout path. This script never
# removes a checkout or creates a Tern session.
set -euo pipefail
export PATH="$HOME/.nix-profile/bin:$HOME/.local/bin:$HOME/bin:$PATH"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

die() { printf 'create.sh: %s\n' "$*" >&2; exit 1; }

# Faithful Bash port of Herdr's slug() — service.go:167-176
#   lowercase + TrimSpace → replace non-[a-z0-9-_/] with '-' → Trim('-')
slug() {
    local v
    v=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
    # TrimSpace: strip leading/trailing whitespace
    v="${v#"${v%%[^[:space:]]*}"}"
    v="${v%"${v##*[^[:space:]]}"}"
    # replace every character not in [a-z 0-9 _ / -] with a dash
    v=$(printf '%s' "$v" | LC_ALL=C.UTF-8 sed 's/[^a-z0-9_/-]/-/g')
    # Trim leading and trailing dashes from the whole string
    v=$(printf '%s' "$v" | sed 's/^-*//; s/-*$//')
    printf '%s' "$v"
}

# ---------------------------------------------------------------------------
# arguments
# ---------------------------------------------------------------------------

CWD="${1:?usage: create.sh <cwd> <branch>}"
BRANCH_RAW="${2:?usage: create.sh <cwd> <branch>}"

# ---------------------------------------------------------------------------
# validate cwd
# ---------------------------------------------------------------------------

[[ -d "$CWD" ]] || die "cwd does not exist: $CWD"

# ---------------------------------------------------------------------------
# repo root — matches repositoryRoot() in service.go:57-65
# filepath.Dir(git rev-parse --path-format=absolute --git-common-dir)
# Works from inside a linked worktree: common-dir always points at the main
# repo's .git, so worktree creation is redirected back to the canonical root.
# ---------------------------------------------------------------------------

GIT_COMMON_RAW=$(git -C "$CWD" rev-parse --path-format=absolute --git-common-dir) \
    || die "$CWD is not inside a Git repository"

# dirname equivalent; matches Go's filepath.Dir exactly
ROOT=$(dirname -- "$GIT_COMMON_RAW")

# ---------------------------------------------------------------------------
# branch slug + validation
# ---------------------------------------------------------------------------

BRANCH=$(slug "$BRANCH_RAW")
[[ -n "$BRANCH" ]] || die "branch name is empty after slug (raw: $BRANCH_RAW)"
git -C "$ROOT" check-ref-format --branch "$BRANCH" >/dev/null 2>&1 \
    || die "invalid Git branch: $BRANCH"

REPO=$(basename -- "$ROOT")

# ---------------------------------------------------------------------------
# target path — matches overlayCreate() base/target layout in service.go:138
# ---------------------------------------------------------------------------

WORKTREES_DIR="${HERDR_WORKTREES_DIR:-$HOME/.herdr/worktrees}"
[[ "$WORKTREES_DIR" == /* ]] || die "HERDR_WORKTREES_DIR must be absolute: $WORKTREES_DIR"
TARGET="$WORKTREES_DIR/$REPO/$BRANCH"

# ---- path-escape guard: target must stay inside WORKTREES_DIR --------------
# mkdir the base dir so pwd -P can resolve it; idempotent.
mkdir -p "$WORKTREES_DIR"
REAL_WDIR=$(cd "$WORKTREES_DIR" && pwd -P)

# Create target's parent now (also needed by git worktree add) then resolve.
# If slug produced a leading '/' that doubles the separator, dirname handles it.
TARGET_PARENT=$(dirname -- "$TARGET")
mkdir -p "$TARGET_PARENT"
REAL_TARGET_PARENT=$(cd "$TARGET_PARENT" && pwd -P)
REAL_TARGET="$REAL_TARGET_PARENT/$(basename -- "$TARGET")"

[[ "$REAL_TARGET" == "$REAL_WDIR/"* ]] \
    || die "target $TARGET escapes worktrees dir $REAL_WDIR — likely a path-escape in branch name"

TARGET="$REAL_TARGET"   # use canonical form from here on

# Reuse a worktree left by a prior session failure, but never claim another
# repository's checkout or a different branch as this workstream.
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    [[ -d "$TARGET" ]] || die "target exists but is not a worktree: $TARGET"
    OWNER=$(git -C "$TARGET" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) \
        || die "target is not a Git worktree: $TARGET"
    EXISTING_BRANCH=$(git -C "$TARGET" symbolic-ref --quiet --short HEAD 2>/dev/null) \
        || die "target has no checked-out branch: $TARGET"
    [[ "$OWNER" == "$GIT_COMMON_RAW" && "$EXISTING_BRANCH" == "$BRANCH" ]] \
        || die "target belongs to a different repository or branch: $TARGET"
    printf '%s\0%s\0%s\0%s\0' "existing" "$TARGET" "$BRANCH" "$ROOT"
    exit 0
fi

# ---------------------------------------------------------------------------
# overlay flow (git-ns) — matches overlayCreate() in service.go:132-160
# Falls back to plain git only when target has NOT been created yet.
# Once the target exists any failure exits immediately to preserve state.
# ---------------------------------------------------------------------------

try_overlay() {
    # service.go:129-131 — gate on 'git ns worktree check'
    git -C "$ROOT" ns worktree check >/dev/null 2>&1 || return 1

    local base="$WORKTREES_DIR/.base-$REPO"
    local snapshot

    # service.go:139-142 — setup base overlay if absent
    if [[ ! -d "$base" ]]; then
        git -C "$ROOT" ns worktree setup "$base" >&2 || {
            printf 'create.sh: git-ns setup failed; falling back to plain git\n' >&2
            return 1
        }
    fi
    local owner
    owner=$(git -C "$base" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
        printf 'create.sh: git-ns base %s is incomplete; falling back to plain git\n' "$base" >&2
        return 1
    }
    if [[ "$owner" != "$GIT_COMMON_RAW" ]]; then
        printf 'create.sh: git-ns base %s belongs to another repository; falling back to plain git\n' "$base" >&2
        return 1
    fi

    # service.go:144-147 — HEAD commit of base is the snapshot anchor
    snapshot=$(git -C "$base" rev-parse HEAD) || {
        printf 'create.sh: git rev-parse HEAD in base %s failed; falling back to plain git\n' "$base" >&2
        return 1
    }

    # service.go:148-150 — record a snapshot for this commit
    git -C "$ROOT" ns worktree snapshot create \
        --base "$base" --commit "$snapshot" >&2 || {
        printf 'create.sh: git-ns snapshot create failed; falling back to plain git\n' >&2
        return 1
    }

    # service.go:151-153 — create the overlay worktree
    # If this command fails we check whether it partially created the target.
    if ! git -C "$ROOT" ns worktree create \
            --base "$base" --snapshot "$snapshot" "$TARGET" >&2; then
        if [[ -e "$TARGET" || -L "$TARGET" ]]; then
            # Partial state: target exists but is incomplete.
            # Never delete; report path so user can inspect.
            die "git-ns worktree create failed; partial target at $TARGET — inspect manually, do not remove without checking"
        fi
        printf 'create.sh: git-ns worktree create failed (no target created); falling back to plain git\n' >&2
        return 1
    fi

    # As in Herdr, attach an existing branch or create a new one.
    if git -C "$TARGET" show-ref --verify --quiet "refs/heads/$BRANCH"; then
        git -C "$TARGET" checkout "$BRANCH" >&2 \
            || die "git checkout $BRANCH failed in overlay at $TARGET — inspect manually"
    else
        git -C "$TARGET" checkout -b "$BRANCH" >&2 \
            || die "git checkout -b $BRANCH failed in overlay at $TARGET — inspect manually"
    fi

    printf '%s\0%s\0%s\0%s\0' "overlay" "$TARGET" "$BRANCH" "$ROOT"
}

# ---------------------------------------------------------------------------
# plain git worktree flow — matches fallback in service.go:50-54
# ---------------------------------------------------------------------------

do_git() {
    # Attach an existing local branch or create a new one from HEAD.
    if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
        git -C "$ROOT" worktree add "$TARGET" "$BRANCH" >&2 \
            || die "git worktree add failed for branch '$BRANCH' at $TARGET"
    else
        git -C "$ROOT" worktree add -b "$BRANCH" "$TARGET" >&2 \
            || die "git worktree add failed for new branch '$BRANCH' at $TARGET"
    fi

    printf '%s\0%s\0%s\0%s\0' "git" "$TARGET" "$BRANCH" "$ROOT"
}

# ---------------------------------------------------------------------------
# run overlay, fall through to git only on pre-target failures
# ---------------------------------------------------------------------------

if ! try_overlay; then
    do_git
fi

