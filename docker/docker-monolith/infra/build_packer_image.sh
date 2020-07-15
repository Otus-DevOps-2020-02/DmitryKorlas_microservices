#!/bin/bash
set -e
packer build  -var-file=packer/variables.json packer/docker-vm.json
