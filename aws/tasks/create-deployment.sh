#!/usr/bin/env bash

set -e -x

source pipelines/shared/utils.sh
source pipelines/aws/utils.sh

: ${BOSH_DIRECTOR_USERNAME:?}
: ${BOSH_DIRECTOR_PASSWORD:?}
: ${RELEASE_NAME:?}
: ${AWS_ACCESS_KEY:?}
: ${AWS_SECRET_KEY:?}
: ${AWS_REGION_NAME:?}
: ${AWS_STACK_NAME:?}

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}
export AWS_DEFAULT_REGION=${AWS_REGION_NAME}

# inputs
manifest_dir=$(realpath deployment-manifest)
deployment_release=$(realpath pipelines/shared/assets/certification-release)
stemcell_dir=$(realpath stemcell)
bosh_cli=$(realpath bosh-cli/bosh-cli-*)
chmod +x $bosh_cli

# configuration
: ${DIRECTOR_IP:=$( stack_info "DirectorEIP" )}

time $bosh_cli -n env ${DIRECTOR_IP//./-}.sslip.io
time $bosh_cli -n login --user=${BOSH_DIRECTOR_USERNAME} --password=${BOSH_DIRECTOR_PASSWORD}

pushd ${deployment_release}
  time $bosh_cli -n create-release --force --name ${RELEASE_NAME}
  time $bosh_cli -n upload-release
popd

time $bosh_cli -n upload-stemcell ${stemcell_dir}/*.tgz
time $bosh_cli -n deploy -d deployment ${manifest_dir}/deployment.yml
