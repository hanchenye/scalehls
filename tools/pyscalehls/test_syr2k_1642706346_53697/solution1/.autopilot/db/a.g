#!/bin/sh
lli=${LLVMINTERP-lli}
exec $lli \
    /home/gregcsl/Desktop/scalehls/tools/pyscalehls/test_syr2k_1642706346_53697/solution1/.autopilot/db/a.g.bc ${1+"$@"}