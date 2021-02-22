#!/bin/bash

# Copy the matcher to a shared volume with the host; otherwise "add-matcher"
# can't find it.
cp /code/luacheck-matcher.json "${HOME}/"
echo "::add-matcher::${HOME}/luacheck-matcher.json"

echo "Running luacheck on '${INPUT_PATH:=.}'..."
luacheck --no-color --codes --formatter plain --ranges "${INPUT_PATH}"
res=$?

echo "::remove-matcher owner=luacheck-error::"
echo "::remove-matcher owner=luacheck-warning::"

exit $res
