#!/bin/bash

exit_status=0

vendor/bundle/bin/rake test || exit_status=1

argos upload tmp/capybara --token $ARGOS_TOKEN \
--reference-branch $HEROKU_TEST_RUN_BRANCH --reference-commit $HEROKU_TEST_RUN_COMMIT_VERSION

curl --request PATCH "${REMOTE_REPORTER_URL}/${HEROKU_TEST_RUN_ID}?node_total=${CI_NODE_TOTAL}"

exit $exit_status
