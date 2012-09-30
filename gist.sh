#! /bin/bash

HEADER="./docs-src/includes/header-gist.html"
FOOTER="./docs-src/includes/footer.html"

EXAMPLE=$1

# return 0 if file $1 was recently changed and should be pushed
# TODO if file was changed in HEAD, push it
function changed {
    if [[ -z $(git status $1 -s --porcelain) ]]; then
        return 1
    fi
    return 0
}

IS_GIST=$(cat $EXAMPLE | head -1 | grep gist)

if [ -n "$IS_GIST" ]; then
    echo "Uploading $EXAMPLE"
    GIST=${IS_GIST##*/}
    changed $EXAMPLE
    if [ $? -eq 0 ]; then
        echo "upload $EXAMPLE"
        cat $HEADER $EXAMPLE $FOOTER | jist -f index.html -u $GIST
    fi
    README=${EXAMPLE/%js/md}
    if [ -f $README ]; then
        changed $README
        if [ $? -eq 0 ]; then
            echo "upload $README"
            cat $README | jist -f README.md -u $GIST
        fi
    fi
fi
