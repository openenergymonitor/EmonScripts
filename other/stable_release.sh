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

        # Get commit messages since last tag (no filtering)
        last_tag=$(git -C $M describe --tags --abbrev=0 HEAD^ 2>/dev/null)
        if [ -z "$last_tag" ]; then
            commit_range=""
        else
            commit_range="$last_tag..HEAD"
        fi

        release_notes=$(git -C $M log $commit_range --pretty=format:"* %s")

        # Create GitHub release with notes
        gh release create "$version" --title "$version" --notes "$release_notes" --target stable

        git -C $M checkout master

        git -C $M merge origin/stable

        git -C $M push origin master
    fi
fi