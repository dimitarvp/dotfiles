#! /bin/sh

wget \
    --execute robots=off \
    --recursive \
    --level 64 \
    --timestamping \
    --continue \
    --page-requisites \
    --adjust-extension \
    --convert-links \
    --restrict-file-names=ascii,lowercase \
    --no-remove-listing \
    --no-parent \
    --tries 5 \
    --timeout 30 \
    --retry-connrefused \
    --xattr \
    --no-host-directories \
    --span-hosts \
    --verbose \
    "$@"

#    --directory-prefix .
#    --limit-rate 78.5k
#    --force-directories
#    --wait 1
#    --random-wait
#    --http-user=USERNAME
#    --http-password=PASSWORD
#    --domains website.org \
    #    www.website.org/tutorials/html/
