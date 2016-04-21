#!/bin/bash -e

function sshrun() {
    host=$1; shift
    ssh -o StrictHostKeyChecking=no -i $HOME/ssh_key vagrant@${host} sudo "$@"
}

function runpuppet() {
    sshrun $1 puppet agent --server boot.seed-stack.local --waitforcert 2 --test
}

for machine in $*; do
    runpuppet ${machine}
done
