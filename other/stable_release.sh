#!/bin/bash

# sudo apt-get install jq gh
# Requires GitHub authentication: set GH_TOKEN environment variable
#
# Setup instructions:
# 1. Go to GitHub -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic)
# 2. Click 'Generate new token (classic)'
# 3. Give it a name, set expiry, and check the 'repo' scope
# 4. Copy the token and add it to your shell profile:
#      echo 'export GH_TOKEN=TOKEN_HERE' >> ~/.bashrc
#      source ~/.bashrc

# Check GitHub CLI authentication
if ! gh auth status &>/dev/null; then
    if [ -z "$GH_TOKEN" ]; then
        echo "Error: GitHub CLI is not authenticated."
        echo "Please run 'gh auth login' or set the GH_TOKEN environment variable."
        exit 1
    fi
fi

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

    # Get repo info from git remote so we can verify GitHub access before making changes.
    remote_url=$(git -C $M config --get remote.origin.url)
    repo=$(echo "$remote_url" | sed -n 's#.*github.com[:/]\(.*\)\.git#\1#p')

    if [ -z "$repo" ]; then
        echo "Error: could not determine GitHub repository from remote origin URL."
        exit 1
    fi

    repo_owner=$(echo "$repo" | cut -d/ -f1)
    repo_name=$(echo "$repo" | cut -d/ -f2-)

    release_permission=$(gh api graphql \
        -f owner="$repo_owner" \
        -f name="$repo_name" \
        -f query='query($owner:String!, $name:String!){repository(owner:$owner, name:$name){viewerPermission}}' \
        --jq '.data.repository.viewerPermission' 2>/dev/null) || {
        echo "Error: GitHub credentials cannot create a release for $repo."
        echo "Please run 'gh auth login' or update GH_TOKEN with a token that has write access."
        exit 1
    }

    if [ "$release_permission" != "ADMIN" ] && [ "$release_permission" != "WRITE" ]; then
        echo "Error: GitHub credentials do not have release permissions for $repo ($release_permission)."
        exit 1
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
        if ! gh release create "$version" --title "$version" --notes "$release_notes" --target stable; then
            echo "Error: failed to create GitHub release for $version."
            exit 1
        fi

        git -C $M checkout master

        git -C $M merge origin/stable

        git -C $M push origin master
    fi
fi