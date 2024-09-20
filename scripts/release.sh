#!/usr/bin/env bash

# A script to compile parsers for all platforms and package them in tar.gz archive.
#
# Order of operations
# 1. Read the CHANGELOG:
#  - Get the previous and current release tags
#  - Get the list of the added/updated/deleted parsers
#
# 2. Check if there are release assets available for download for those previous release tag
#
# 3. Assets exist:
#  - true:  Download the assets, extract archive, compile the updated/added parsers, delete the removed parsers, archive the parsers for upload
#  - false: Compile all the parsers, archive them for upload

set -x
set -e

ZIG_COMPILE_TARGETS=(
   "x86_64-linux"
   "aarch64-linux"
   "x86_64-macos"
   "aarch64-macos"
   "x86_64-windows"
)

REPO_OWNER="KevinSilvester"
REPO_NAME="nvim-treesitter-parsers"

function _main() {
   local current_release_tag=$(jq -r '.[0].tag' CHANGELOG.json)
   local previous_release_tag=$(jq -r '.[1].tag' CHANGELOG.json)

   local added_parsers=($(jq -r '.[0].changes.added[]' CHANGELOG.json))
   local updated_parsers=($(jq -r '.[0].changes.updated[]' CHANGELOG.json))
   local removed_parsers=($(jq -r '.[0].changes.removed[]' CHANGELOG.json))

   for target in ${ZIG_COMPILE_TARGETS[@]}; do
      local release_url=$(_release_url $previous_release_tag $target)

      if _check_release_exists $release_url; then
         _download_and_extract $release_url
         _compile_parsers $target "added" ${added_parsers[@]}
         _compile_parsers $target "updated" ${added_parsers[@]}
         _delete_parsers ${removed_parsers[@]}
         _archive_parsers $current_release_tag $target
      else
         _compile_all_parsers $target
         _archive_parsers $current_release_tag $target
      fi
   done
}

# Check f there a previous release
function _check_release_exists() {
   local url=$1

   if [ $(curl -L -s -o /dev/null -w "%{http_code}" $url) -eq 404 ]; then
      return 1
   else
      return 0
   fi
}

function _release_url() {
   local tag=$1
   local target=$2
   echo "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$tag/parsers-$tag-$target.tar.gz"
}

# Download and extract the previous release assets to /tmp
function _download_and_extract() {
   local url=$1

   echo "::notice::Downloading and extracting $url"

   mkdir -p /tmp
   wget -qO- $url | tar xzf - -C /tmp
}

# Compile the added/updated parsers
function _compile_parsers() {
   local target=$1
   local type=$2
   local parsers=(${@:3})

   if [ ${#parsers[@]} -eq 0 ]; then
      echo "::notice::No parsers $type"
      return 0
   fi

   echo "::notice::Compiling $type parsers: ${parsers[@]}"
   ts-parsers compile \
      --no-fail-fast \
      --compiler zig \
      --target $target \
      --destination /tmp/parser \
      "${parsers[@]}"
}

# Delete the removed parsers
function _delete_parsers() {
   if [ $# -eq 0 ]; then
      echo "::notice::No parsers removed"
      return 0
   fi

   echo "::notice::Deleting removed parsers: $@"
   for parser in "$@"; do
      rm -r "/tmp/parser/$parser.so"
   done
}

# Compile all the parsers
function _compile_all_parsers() {
   local target=$1

   echo "::notice::Compiling all parsers"
   ts-parsers compile \
      --all \
      --no-fail-fast \
      --compiler zig \
      --target $target \
      --destination /tmp/parser
}

# Archive the parsers
function _archive_parsers() {
   local tag=$1
   local target=$2

   echo "::notice::Archiving parsers"
   tar czf "parsers-$tag-$target.tar.gz" -C /tmp parser
   rm -r /tmp/parser
}

_main
