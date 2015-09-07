#!/usr/bin/env bash

PARAMS="-u ${MYSQL_USER:-root}"
[[ -z "$MYSQL_PASS" ]] || PARAMS="$PARAMS -P '${MYSQL_PASS}'"
[[ -z "$MYSQL_ASK_PASS" ]] || PARAMS="$PARAMS -p"

mysql $PARAMS -e "create database amethyst_model_test"
mysql $PARAMS -e "create user 'amethyst_model'@'localhost'"
mysql $PARAMS -e "grant all on amethyst_model_test.* to 'amethyst_model'@'localhost'"

createdb amethyst_model_test
createuser amethyst_model
