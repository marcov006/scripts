#!/bin/bash
set -eux

function plus_one_patch()
{
    local _patch_number=$i
    `ssh -p 29418 opticm6.rds.intel.com gerrit query --current-patch-set $_patch_number > .patch_$_patch_number`
    local _ref=`cat .patch_$_patch_number | grep "refs" | awk '{ print $2 }'`
	local _patch=$(basename $_ref)
	echo $_patch_number,$_patch would get its +1
	`ssh -p 29418 opticm6.rds.intel.com gerrit review --code-review +1 $_patch_number,$_patch`
    rm .patch_$_patch_number
}

main()
{
    for i in $*; do
	plus_one_patch $i
    done
}

main $*
