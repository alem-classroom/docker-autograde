#!/bin/bash

set -eu

API_KEY=$1
COURSE_TEST_URL=$2
USER_KEY=$3

echo "$(cat /etc/hosts | sed s/localhost/autogradehost/g)" > /etc/hosts
echo "$(/sbin/ip route | awk '/default/ { print $3 }') localhost" >> /etc/hosts

#####

# API_KEY=1
# COURSE_TEST_URL='alem-classroom/test-docker'
# USER_KEY=1
# GITHUB_REPOSITORY='alem-classroom/solution-docker'
# GITHUB_ACTOR='atlekbai'

#####

export INPUT_GRADE="good job, contact me @frozen6heart"
export INPUT_URL="good job, contact me @frozen6heart"
export INPUT_TOKEN="good job, contact me @frozen6heart"


TEST=${COURSE_TEST_URL##*/test-}
TEST_FULL="$TEST/test-"
SOLUTION="solution"

SOLUTION_URL="https://$USER_KEY@github.com/${GITHUB_REPOSITORY}"
TEST_URL="https://$USER_KEY@github.com/${COURSE_TEST_URL}"

printf "📝 hello $GITHUB_ACTOR\n"
printf "⚙️  building enviroment\n"
printf "⚙️  cloning solutions\n"
git clone $SOLUTION_URL $SOLUTION
git clone $TEST_URL $TEST
printf "⚙️  cloning finished\n"

find $TEST -type f -name '*test*' -print0 | xargs -n 1 -0 -I {} bash -c 'set -e; f={}; cp $f $0/${f:$1}' $SOLUTION ${#TEST_FULL}
curl_course=$(curl -w '' -s https://lrn.dev/api/curriculum/courses/$TEST | jq -c '.lessons[] | select(.lesson_type=="project") | {name: .name, index: .index}')

send_result(){
    data=$(jq -aRs . <<< ${5})
    curl -s -X POST "https://lrn.dev/api/curriculum/lessons/project" -H "x-grade-secret: ${1}" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"username\":\"${2}\", \"lessonName\":\"${3}\", \"status\": \"${4}\", \"log\": ${data}}"
    echo ""
}

for project in $curl_course; do
    LESSON_NAME=$(echo $project | jq -r '.name' | sed s/-docker//g)
    echo $LESSON_NAME

    cd $SOLUTION/$LESSON_NAME &> /dev/null
    set +e
    result=$(bash test-$LESSON_NAME.sh)
    last="$?"
    set -e
    echo "${result}"
    cd ../../ &> /dev/null
    
    if [[ $last -eq 0 ]]; then
        printf "✅ $LESSON_NAME-$TEST passed\n"
        send_result $API_KEY $GITHUB_ACTOR $LESSON_NAME-$TEST "finished" "${result}"
    else
        printf "🚫 $LESSON_NAME-$TEST failed\n"
        send_result $API_KEY $GITHUB_ACTOR $LESSON_NAME-$TEST "failed" "${result}"
        exit 1
    fi
done

printf "👾👾👾 done 👾👾👾\n"
