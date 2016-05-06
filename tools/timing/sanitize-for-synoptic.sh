#!/bin/sh

grep -v 'lock' $1 | grep -v 'evict candidates' | grep -v 'evict entries' > $1.sz
