#!/bin/sh

grep -v 'lock' | grep -v 'evict candidates' | grep -v 'evict entries' $1 > $1.sz
