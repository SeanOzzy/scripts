#!/bin/bash
# This script searches for a string in a Postgres commit logs to identify which branches and tags contain the commit.
# This can be useful when a known bug has been fixed in a commit but you need to confirm which version contains the change.

PG_SOURCE_DIR="$PWD/postgres-source"
main() {
    if [[ -z "$1" ]]; then
        echo "Missing argument, string of text or commit hash required"
        exit 1
    fi
    # Check if the postgres directory exists in the current directory
    if [[ ! -d "$PG_SOURCE_DIR" ]]; then
        echo "A directory "$PG_SOURCE_DIR" not found, cloning..."
        git clone https://git.postgresql.org/git/postgresql.git "$PG_SOURCE_DIR"
    fi

    cd "$PG_SOURCE_DIR" || exit

    # Check if the directory is a git repo
    if ! git rev-parse --is-inside-work-tree; then
        echo "A directory named "$PG_SOURCE_DIR" exists but is not a git repo, exiting..."
        exit 1
    fi

    echo "Updating master branch"
    git checkout master
    git pull
    SEARCH="$1"
    cd - || exit

    # Using regex to determine if $1 is likely a commit hash
    if [[ $SEARCH =~ ^[0-9a-fA-F]+$ ]]; then
        search_commit_hash "$SEARCH"
    else
        search_commit_text "$SEARCH"
    fi
}

# if $1 appears to be a string, search for it in the commit descriptions
search_commit_text() {
    cd "$PG_SOURCE_DIR" || exit
    echo
    echo "Searching commit description for \"$SEARCH\" in commit(s) for the following branch(s)..."
    git branch -lr | awk '{print$1}' | xargs -IBRANCH -P99 bash -c "git log BRANCH --oneline --color --grep='$SEARCH' | while read C; do echo \$C | sed 's: : BRANCH :'; done" | sort
    echo
    echo "Searching commit description for tag(s) containing the commit hash(s)..."
    echo "$SEARCH" | xargs -I {} git log --all --grep="{}" --color --pretty=format:"%h %s" | while read -r hash desc; do
        git tag --contains "$hash" | while read -r tag; do
            echo "Tag: $tag Contains Hash: $hash Subject: $desc"
        done
    done | sort -t":" -k2 -u
    echo
    echo "Search complete, read via browser https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=\$COMMIT_HASH"
    cd - || exit
    exit 0
}

# If $1 appears to be a commit hash, use this function to search for it in branches and tags
search_commit_hash() {
    cd "$PG_SOURCE_DIR" || exit
    echo "Searching for commit hash \"$SEARCH\" in branches.... "
    git branch -lr | awk '{print$1}' | xargs -IBRANCH -P99 bash -c "git log BRANCH --oneline --color --grep='$SEARCH' | while read C; do echo \$C | sed 's: : BRANCH :'; done" | sort
    # git branch --contains "$1"
    echo
    echo "Searching for commit hash \"$SEARCH\" in tags.... "
    git tag --contains "$1"
    echo
    cd - || exit
    exit 0
}

main "$@"
