#!/bin/bash

exit_status=0

bin/rake test || exit_status=1

argos upload tmp/capybara --token aaacbbd69f88ea80cbfe34055c2974cfc3b9ef04 \
--branch $HEROKU_TEST_RUN_BRANCH --commit $HEROKU_TEST_RUN_COMMIT_VERSION

exit $exit_status