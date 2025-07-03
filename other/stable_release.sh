#!/bin/bash

# sudo apt-get install jq gh

M=$(pwd)

if [ -d "$M/.git" ]; then

    if [ -f "$M/module.json" ]; then
        version=$(cat "$M/module.json" | jq -r '.version')
    elif [ -f "$M/version.json" ]; then
        version=$(cat "$M/version.json" | jq -r '.version')
    else
        echo "module or version file not found"
        exit 0
    fi

    changes=$(git -C $M diff-index HEAD --)
    if [ "$changes" = "" ]; then

        echo "Creating stable release for: $M $version"

        git -C $M fetch --all --prune

        git -C $M checkout stable

        git -C $M pull origin stable

        git -C $M merge origin/master

        git -C $M push origin stable

        git -C $M tag -a $version -m $version

        git -C $M push origin $version

        # Get repo info from git remote
        remote_url=$(git -C $M config --get remote.origin.url)
        repo=$(echo "$remote_url" | sed -n 's#.*github.com[:/]\(.*\)\.git#\1#p')

        # Get commit messages since last tag (no filtering)
        last_tag=$(git -C $M describe --tags --abbrev=0 HEAD^ 2>/dev/null)
        if [ -z "$last_tag" ]; then
            commit_range=""
            compare_url=""
        else
            commit_range="$last_tag..HEAD"
            compare_url="https://github.com/$repo/compare/$last_tag...$version"
        fi

        release_notes=$(git -C $M log $commit_range --pretty=format:"* %s")

        # Append compare link if available
        if [ -n "$compare_url" ]; then
            release_notes="$release_notes

[Full commit diff]($compare_url)"
        fi

        # Create GitHub release with notes
        gh release create "$version" --title "$version" --notes "$release_notes" --target stable

        git -C $M checkout master

        git -C $M merge origin/stable

        git -C $M push origin master
    fi
fi