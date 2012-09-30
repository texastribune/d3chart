#! /bin/bash

HEADER="./docs-src/header-gist.html"
FOOTER="./docs-src/footer.html"

EXAMPLE=$1

# takes input
# echo test=$test
# echo $content
IS_GIST=$(cat $EXAMPLE | head -1 | grep gist)
# echo $EXAMPLE $IS_GIST
if [ -n "$IS_GIST" ]; then
    echo "Uploading $EXAMPLE"
    GIST=${IS_GIST##*/}
    cat $HEADER $EXAMPLE $FOOTER | jist -f index.html -u $GIST
    README=${EXAMPLE/%js/md}
    if [ -f $README ]; then
        cat $README | jist -f README.md -u $GIST
    fi
fi
