#!/usr/local/bin/bash

sqlite3 bot.sqlite < users.sql
sqlite3 bot.sqlite < configs.sql

