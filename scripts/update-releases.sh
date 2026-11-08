#!/usr/bin/env bash
set -euo pipefail

owner="${1:-opikdev}"
readme="${2:-README.md}"
limit="${3:-5}"

list=$(gh api graphql -f owner="$owner" -f query='
  query($owner: String!) {
    user(login: $owner) {
      repositories(first: 100, privacy: PUBLIC, isFork: false) {
        nodes { name isArchived latestRelease { tagName url publishedAt } }
      }
    }
  }' --jq "
  [.data.user.repositories.nodes[]
    | select(.latestRelease != null and (.isArchived | not))
    | {name, tag: .latestRelease.tagName, url: .latestRelease.url, at: .latestRelease.publishedAt}]
  | sort_by(.at) | reverse | .[:$limit][]
  | \"- [\(.name) \(.tag)](\(.url)) · \(.at | fromdateiso8601 | strftime(\"%b %d, %Y\") | sub(\" 0\"; \" \"))\"")

LIST="$list" awk '
  /<!-- releases:start -->/ { print; print ENVIRON["LIST"]; skip = 1; next }
  /<!-- releases:end -->/ { skip = 0 }
  !skip
' "$readme" > "$readme.tmp"
mv "$readme.tmp" "$readme"
