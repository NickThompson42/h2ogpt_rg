#!/bin/bash

# Check if the user has supplied an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <GCP Bucket Directory>"
    exit 1
fi

# Sync the given GCP bucket directory to $HOME/h2ogpt_rg
gsutil -m rsync -r $1 $HOME/h2ogpt_rg
