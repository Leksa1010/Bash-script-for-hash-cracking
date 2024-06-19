#!/bin/bash

usage() {
    echo "Usage: $0 -h <hash_file> -w <wordlist_file> [-a <algorithm>] [-t <threads>] [-v]"
    exit 1
}

# Cracking function
crack_password() {
    local HASH=$1
    local WORD=$2
    local ALG=$3

    case $ALG in
        md5) HASHED_PASSWORD=$(echo -n $WORD | md5sum | awk '{print $1}') ;;
        sha1) HASHED_PASSWORD=$(echo -n $WORD | sha1sum | awk '{print $1}') ;;
        sha256) HASHED_PASSWORD=$(echo -n $WORD | sha256sum | awk '{print $1}') ;;
        sha512) HASHED_PASSWORD=$(echo -n $WORD | sha512sum | awk '{print $1}') ;;
        *) echo "Unsupported hash algorithm: $ALG" ; exit 1 ;;
    esac

    if [ "$HASH" == "$HASHED_PASSWORD" ]; then
        echo "Password found: $WORD for hash: $HASH"
        echo "Password found: $WORD for hash: $HASH" >> $OUTPUT_FILE
    elif [ "$VERBOSE" = true ]; then
        echo "Tried: $WORD - Hash: $HASHED_PASSWORD"
    fi
}

# Default values
ALGORITHM="sha256"
THREADS=4
VERBOSE=false
OUTPUT_FILE="crack_results.txt"

# Parse command-line arguments
while getopts h:w:a:t:v opt; do
        case $opt in
                h) HASH_FILE=$OPTARG ;;
                w) WORDLIST=$OPTARG ;;
                a) ALGORITHM=$OPTARG ;;
                t) THREAD=$OPTARG ;;
                v) VERBOSE=true ;;
                *) usage
        esac
done

if [ -z "$HASH_FILE" ] || [ -z "$WORDLIST" ]; then
        usage
fi

# Start cracking
echo "Reading hash from $HASH_FILE file..."
echo "Using $WORDLIST as wordlist..."
echo "Starting password cracking using $ALGORITHM algorithm..."
echo "Using $THREADS threads..."

# Export functions and variables for parallel execution
export -f crack_password
export ALGORITHM
export VERBOSE
export OUTPUT_FILE

# Read wordlist and lauch cracking attempts
cat "$HASH_FILE" | parallel -j $THREADS --pipe -N 1 "while read HASH; do while read WORD; do crack_password \$HASH \$WORD \$ALGORITHM; done < $WORDLIST; done"

echo "Cracking completed. Result saved to $OUTPUT_FILE"
