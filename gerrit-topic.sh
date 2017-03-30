#!/bin/bash
#set -eux

REMOTE=origin
URL="android.intel.com "

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 bundle_id" >&2
	exit 1
fi

`ssh -p 29418 $URL gerrit query topic:$1 status:open > .patch_$1`
_nr=`cat .patch_$1 | grep "rowCount: " | awk ' { print $2 } '`
_ids=`cat .patch_$1 | grep "number: " | awk ' { print $2 } '`
echo $_nr patches availables for bundle: $1

for _id in $_ids; do
	echo "gerrit-cherry-pick --latest $REMOTE $_id"
#	gerrit-cherry-pick --latest $REMOTE $_id
done
rm .patch_$1
