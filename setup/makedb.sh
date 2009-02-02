#!/usr/bin/env bash

sqlite3 db/bot.sqlite < sql/users.sql
sqlite3 db/bot.sqlite < sql/hosts.sql
sqlite3 db/bot.sqlite < sql/channels.sql

