#!/bin/bash
jobid=$1
state=$(sacct -j "$jobid" --format=State --noheader | head -1 | tr -d ' ')
if [ -z "$state" ]; then
    echo running
else
    case "$state" in
        PENDING|RUNNING|REQUEUED|SUSPENDED) echo running ;;
        COMPLETED) echo success ;;
        *) echo failed ;;
    esac
fi
