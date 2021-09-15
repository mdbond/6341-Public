#!/bin/bash

do_one_test() {
    POINTS=$1
    PROGRAM=$2
    INPUT=$3
    shift 3
    OPTIONS=$(echo $* | sed -e 's/#.*$//') # removes comments
    echo -n "Testing $OPTIONS $PROGRAM $INPUT, worth $POINTS points: "
    # Compare the last line if process returns nonzero code; otherwise compare last two lines

    # Uncomment to see reference interpreter output only:
    # echo ""
    # $REF_IMPL $OPTIONS -ct 5 $TESTCASE_DIR/$PROGRAM $INPUT
    # echo ""
    # return

    # Get interpreter return and quandary process return (last 2 lines) of ref and sub implementations
    REF_OUT=$($REF_IMPL $OPTIONS $TESTCASE_DIR/$PROGRAM $INPUT 2>&1 | tail -2)
    SUB_OUT=$($TIMEOUT ./quandary $OPTIONS $TESTCASE_DIR/$PROGRAM $INPUT 2>&1 | tail -2)
    # If the ref quandary process exited with a nonzero code, we only care about
    # the quandary process return value (the last line)
    if [[ $(echo "$REF_OUT" | tail -1) != "Quandary process returned 0" ]]; then
        REF_OUT=$(echo "$REF_OUT" | tail -1)
        SUB_OUT=$(echo "$SUB_OUT" | tail -1)
    fi

    MAX_SCORE=$((MAX_SCORE + POINTS))
    if [ "$REF_OUT" == "$SUB_OUT" ]; then
        echo PASSED
        SCORE=$((SCORE + POINTS))
    else
        if [ "$SUB_OUT" == "" ]; then
            echo 'FAILED (timeout?)'
        else
            echo FAILED
        fi
        # Uncomment to debug FAILED test cases only:
        # echo REF_OUT is $REF_OUT 
        # echo SUB_OUT is $SUB_OUT
    fi
    # Uncomment to debug ALL test cases:
    # echo REF_OUT is $REF_OUT
    # echo SUB_OUT is $SUB_OUT
}

if [ "$#" -ne 5 ] && [ "$#" -ne 6 ]; then
    echo Usage: grade.sh SUBMISSION_TGZ REF_IMPL TESTCASES_FILE TESTCASE_DIR DEFAULT_MAKEFILE [TIMEOUT_IN_SECONDS]
    exit
fi

if [ -z "$JFLEX_DIR" ]; then
    echo JFLEX_DIR isn\'t set
    exit
fi
if [ -z "$CUP_DIR" ]; then
    echo CUP_DIR isn\'t set
    exit
fi

SUBMISSION_TGZ=$1

export TMPDIR=.
SUBMISSION_DIR=$(mktemp -d)

# Remove tmp directory
INITIAL_DIR=$(pwd)
trap "cd $INITIAL_DIR && rm -rf $SUBMISSION_DIR" EXIT

if ! [ -x "$(command -v realpath)" ]; then
    echo 'Command realpath is not installed. Trying something else, but $2 and $4 need to be relative paths for it to work!'
    REF_IMPL="../$2"
    TESTCASES_FILE="../$3"
    TESTCASE_DIR="../$4"
    DEFAULT_MAKEFILE=$(realpath --relative-to=$SUBMISSION_DIR $5)
else
    REF_IMPL=$(realpath --relative-to=$SUBMISSION_DIR $2)
    TESTCASES_FILE=$(realpath --relative-to=$SUBMISSION_DIR $3)
    TESTCASE_DIR=$(realpath --relative-to=$SUBMISSION_DIR $4)
    DEFAULT_MAKEFILE=$(realpath --relative-to=$SUBMISSION_DIR $5)
fi
TIMEOUT=""
if [ "$#" -eq 6 ]; then
    TIMEOUT="timeout $6"
fi

# Extract the submitted .tgz to a new directory
echo Extracting submission to $SUBMISSION_DIR, will perform testing there
gzip -cd "$SUBMISSION_TGZ" | tar xf - -C $SUBMISSION_DIR

# Build the submitted project
SUBMISSION_DIR=$(realpath $SUBMISSION_DIR)
cd $SUBMISSION_DIR
COMPILE_SUCCESS=1
make clean && make
if [[ $? -ne 0 ]]; then
    echo WARNING: Couldn\'t run make. Is the .tgz directory structure incorrect?
    ACTUAL_MAKEFILE=$(find | grep '/Makefile\|/makefile')
    if [[ ! -f $ACTUAL_MAKEFILE ]]; then 
        COMPILE_SUCCESS=0
    else
        ACTUAL=$(dirname $ACTUAL_MAKEFILE)
        REF_IMPL=$(realpath --relative-to=$ACTUAL $REF_IMPL)
        TESTCASES_FILE=$(realpath --relative-to=$ACTUAL $TESTCASES_FILE)
        TESTCASE_DIR=$(realpath --relative-to=$ACTUAL $TESTCASE_DIR)
        echo Found $ACTUAL_MAKEFILE, trying to build and execute from $ACTUAL...
        cd $ACTUAL
        COMPILE_SUCCESS=true
        make clean && make
        if [[ $? -ne 0 ]]; then
            COMPILE_SUCCESS=0
        fi
    fi
fi

if [ $COMPILE_SUCCESS -eq 0 ]; then
    echo Compile using the default Makefile
    cd $SUBMISSION_DIR
    cp $DEFAULT_MAKEFILE $SUBMISSION_DIR
    make clean && make
    if [[ $? -ne 0 ]]; then exit 1; fi
fi

# Test each test case
SCORE=0
while IFS= read -r line; do
    #echo do_one_test $line
    do_one_test $line
done <$TESTCASES_FILE

echo Total score: $SCORE out of $MAX_SCORE

if [[ $SCORE -ne $MAX_SCORE ]]; then
    exit 2
fi
