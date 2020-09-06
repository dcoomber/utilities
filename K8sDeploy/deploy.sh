#!/bin/bash
# A shell script to deploy the current git clone to K8s
# Written by: David Coomber
# Last updated on: 17 February 2020
# -------------------------------------------------------

#  https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux

function usage {
    echo
    echo "A shell script to deploy the current git clone to K8s"
    echo
    echo "usage: $0 config_file [relativepath]"
    echo "  config_file       file containing namespace-specific detail (within the deployment script config sub-directory)"
    echo "  relativepath      optional github clone sub-directory containing the Dockerfile for deployment"
    echo
    exit 1
}

# validate script arguments
if [ -z "$1" ]; then
    echo
    echo "Missing required argument 'config_file'."
    usage
fi

# import settings from configuration file
config_dir=$(dirname "$0")/config
defaults="$config_dir/defaults"
config="$config_dir/$1"

# validate configuration
if [ ! -f "$defaults" ]; then
    echo
    printf "${ERROR}Configuration file not found at '%s'.${NC}\n" "${defaults}"
    usage
fi

if [ ! -f "$config" ]; then
    echo
    printf "${ERROR}Configuration file not found at '%s'${NC}\n" "$config"
    usage
fi

# load configuration
# shellcheck source=config/defaults
source "${defaults}"

# shellcheck source=config/uat
source "${config}"

# work in source repo directory
pushd "$PWD" > /dev/null || exit

# set Dockerfile path
if [ "$2" == "" ]; then
    dockerfile=Dockerfile
    app=${app}
else
    dockerfile="$2/Dockerfile"
    app=$2
fi

# directory must contain a Dockerfile
if [ ! -f "${dockerfile}" ]; then
    printf "${ERROR}Dockerfile doesn't exist in the specified directory:${NC} %s\n" "${dockerfile}"
    usage
fi

# must be run from within a git repo directory
if ! git status; then
    # shellcheck disable=SC2059
    printf "${ERROR}This script must be executed from within a valid git repo clone.${NC}\n"
    usage
fi

# pull local branch (update)
if ! git pull; then
    # shellcheck disable=SC2059
    printf "${ERROR}Could not pull branch.  See previous errors.${NC}\n"
    usage
fi

# build the image
IMAGE_PATH="${IMAGE_PATH}_ROOT/${app}:${BRANCH}"
printf "\n${WARNING}Building image (%s)${NC}\n" "${IMAGE_PATH}"

printf "  docker build -t %s -f %s .\n" "${IMAGE_PATH}" "${dockerfile}"
printf "    or\n"
printf "  docker build -t %s -f %s --no-cache .\n" "${IMAGE_PATH}" "${dockerfile}"

if ! docker build -t "${IMAGE_PATH}" -f "${dockerfile}" --no-cache .; then
    # shellcheck disable=SC2059
    printf "\n${ERROR}Building image failed.  See above for details.${NC}\n\n"
    exit 1
fi

# push the image
# shellcheck disable=SC2059
printf "\n${WARNING}Pushing image${NC}\n"
printf "docker push %s\n" "${IMAGE_PATH}"

if ! docker push "${IMAGE_PATH}"; then
    # shellcheck disable=SC2059
    printf "\n${ERROR}Pushing image failed.  See above for details.${NC}\n\n"
    exit 1
fi

# delete pod to force deployment of new image
# shellcheck disable=SC2059
printf "\n${WARNING}Deleting pods${NC}\n"

if ! kubectl --context "${CONTEXT}" -n "${NAMESPACE}" delete pods -l app="${app}"; then
    # shellcheck disable=SC2059
    printf "\n${ERROR}Deleting pods failed.  See above for details.${NC}\n\n"
    exit 1
fi

# shellcheck disable=SC2059
printf "${WARNING}To delete pods${NC}\n"
printf "  kubectl --context %s -n %s delete pods -l app=%s\n\n" "${CONTEXT}" "${NAMESPACE}" "${app}"

# view status
# shellcheck disable=SC2059
printf "${WARNING}To monitor pod start-up:${NC}\n"
printf "  kubectl --context %s -n %s get pods -w\n" "${CONTEXT}" "${NAMESPACE}"
printf "    or\n"
printf "  kubectl --context %s -n %s get pods -w | grep %s\n\n" "${CONTEXT}" "${NAMESPACE}" "${app}"

# shellcheck disable=SC2059
printf "${WARNING}To view ingress details:${NC}\n"
printf "  kubectl --context %s get ing -n %s\n" "${CONTEXT}" "${NAMESPACE}"
printf "    or\n"
printf "  kubectl --context %s get ing -n %s | grep %s\n\n" "${CONTEXT}" "${NAMESPACE}" "${app}"

# shellcheck disable=SC2059
printf "${WARNING}To change helm installation (update the <<HOST>> in the command below)${NC}\n"
printf "  helm --kube-context %s --namespace %s upgrade --force --install %s-%s --set image.tag=%s,ingress.vhost=${WARNING}<<HOST>>${NC}.%s.env charts/%s\n\n" "${CONTEXT}" "${NAMESPACE}" "${app}" "${BRANCH}" "${BRANCH}" "${NAMESPACE}" "${app}"

# shellcheck disable=SC2059
printf "${WARNING}To check your deployment config:${NC}\n"
# ${NAMESPACE} must be included in metadata/namespace AND metadata/selfLink
# ${BRANCH} must be inclued in spec/template/spec/image
printf "  kubectl --context %s -n %s edit deployment %s\n\n" "${CONTEXT}" "${NAMESPACE}" "${app}"

# shellcheck disable=SC2059
printf "${WARNING}To view application logs:${NC}\n"
printf "  stern --context %s --namespace %s -l app=%s --tail 100 | grep ${WARNING}<<search term>>${NC}\n\n" "${CONTEXT}" "${NAMESPACE}" "${app}" "${CONTEXT}"

# shellcheck disable=SC2059
printf "${WARNING}To edit your namespace:${NC}\n"
printf "  kubectl --context %s edit ns %s\n\n" "${CONTEXT}" "${NAMESPACE}"

# shellcheck disable=SC2059
printf "${WARNING}To view pod details and events:${NC}\n"
printf "  kubectl --context %s describe pods -n %s ${WARNING}<<pod_name>>${NC}\n" "${CONTEXT}" "${NAMESPACE}"

popd > /dev/null || exit
