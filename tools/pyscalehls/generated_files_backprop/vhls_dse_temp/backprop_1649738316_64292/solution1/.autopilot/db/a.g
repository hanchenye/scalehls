#!/bin/sh
lli=${LLVMINTERP-lli}
exec $lli \
    /home/gregcsl/Desktop/scalehls/tools/pyscalehls/generated_files_backprop/vhls_dse_temp/backprop_1649738316_64292/solution1/.autopilot/db/a.g.bc ${1+"$@"}
