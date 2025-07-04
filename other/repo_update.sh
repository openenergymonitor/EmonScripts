#!/bin/bash

update_repo() {
    local repo_dir="$1"

    # if symlink, resolve to the actual directory
    if [ -L "$repo_dir" ]; then
        repo_dir=$(readlink -f "$repo_dir")
        # move one level up to the actual repository directory
        repo_dir=$(dirname "$repo_dir")
    fi

    if [ -d "$repo_dir/.git" ]; then
        echo "Updating repository: $repo_dir"

        local branch
        branch=$(git -C "$repo_dir" branch | grep \* | cut -d ' ' -f2)
        echo "- current branch: $branch"

        local changes
        changes=$(git -C "$repo_dir" diff-index -G. HEAD --)
        if [ "$changes" = "" ]; then
            echo "- local changes: no"
            local result
            result=$(git -C "$repo_dir" fetch --all --prune)
            if [ $result ]; then
                echo "- git fetch: $result"
            fi
            result=$(git -C "$repo_dir" pull --no-rebase)
            echo "- git pull: $result"
        else 
            echo "WARNING local changes in $repo_dir - Module not updated"
            local result
            result=$(git -C "$repo_dir" status)
            echo "- git status: $result"
        fi

        echo
    fi


}

# Update core emoncms repository
update_repo "$(pwd)"

# Update emoncms modules /var/www/emoncms/Modules
if [ -d "Modules" ]; then
    for M in Modules/*; do
        update_repo "$M"
    done
fi