#!/bin/bash
for file in $@; do
	echo "formatting $file"
	fnlfmt --fix $file
done
