#!/bin/bash
# A shell script to deploy the current git clone to K8s
# Written by: David Coomber
# Last updated on: 10 February 2020
# -------------------------------------------------------

#  https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux

function usage {
    echo
    echo "A shell script to deploy the current git clone to K8s"
    echo
    echo "usage: $0 config_file [relativepath]"
    echo "  config_file       file name of the relevant namespace config file in .config"
    echo "  relativepath      optional sub-directory containing a valid Dockerfile"
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
config_dir=$(dirname "$0")/.config
defaults="$config_dir/defaults"
config="$config_dir/$1"

# validate configuration
if [ ! -f "$defaults" ]; then
    echo
    printf "${ERROR}Configuration file not found at '$defaults'.${NC}\n"
    usage
fi

if [ ! -f "$config" ]; then
    echo
    printf "${ERROR}Configuration file not found at '$config'.${NC}\n"
    usage
fi

# load configuration
source "$defaults"
source "$config"

# work in source repo directory
pushd $PWD > /dev/null

# set Dockerfile path
if [ "$2" == "" ]; then
    dockerfile=Dockerfile
    app=$APP
else
    dockerfile="$2/Dockerfile"
    app=$2
fi

# directory must contain a Dockerfile
if [ ! -f "$dockerfile" ]; then
    printf "${ERROR}Dockerfile doesn't exist in the specified directory:${NC} $dockerfile\n"
    usage
fi

# must be run from within a git repo directory
if ! git status; then
    printf "${ERROR}This script must be executed from within a valid git repo clone.${NC}\n"
    usage
fi

# pull local branch (update)
if ! git pull; then
    printf "${ERROR}Could not pull brach.  See previous errors.${NC}\n"
    usage
fi

# build the image
IMAGE_PATH="$IMAGE_PATH_ROOT/$app:$BRANCH"
echo
printf "${WARNING}Building image ($IMAGE_PATH)${NC}\n"

echo "  docker build -t $IMAGE_PATH -f $dockerfile ."
echo "    or"
echo "  docker build -t $IMAGE_PATH -f $dockerfile --no-cache ."
if ! docker build -t $IMAGE_PATH -f $dockerfile .; then
    echo
    printf "${ERROR}Building image failed.  See above for details.${NC}\n"
    echo
    exit 1
fi

# push the image
echo
printf "${WARNING}Pushing image${NC}\n"
echo "docker push $IMAGE_PATH"

if ! docker push $IMAGE_PATH; then
    echo
    printf "${ERROR}Pushing image failed.  See above for details.${NC}\n"
    echo
    exit 1
fi

# delete pod to force deployment of new image
echo
printf "${WARNING}Deleting pods${NC}\n"

if ! kubectl --context $CONTEXT -n $NAMESPACE delete pods -l app=$app; then
    echo
    printf "${ERROR}Deleting pods failed.  See above for details.${NC}\n"
    echo
    exit 1
fi

printf "${WARNING}To delete pods${NC}\n"
echo "  kubectl --context $CONTEXT -n $NAMESPACE delete pods -l app=$app"

# view status
echo
printf "${WARNING}To monitor pod start-up:${NC}\n"
echo "  kubectl --context $CONTEXT -n $NAMESPACE get pods -w"
echo "    or"
echo "  kubectl --context $CONTEXT -n $NAMESPACE get pods -w | grep $app"

echo
printf "${WARNING}To view ingress details:${NC}\n"
echo "  kubectl --context $CONTEXT get ing -n $NAMESPACE"
echo "    or"
echo "  kubectl --context $CONTEXT get ing -n $NAMESPACE | grep $app"

echo
printf "${WARNING}To change helm installation (update the <<HOST>> in the command below)${NC}\n"
printf "  helm --kube-context $CONTEXT --namespace $NAMESPACE upgrade --force --install $app-$BRANCH --set image.tag=$BRANCH,ingress.vhost=${WARNING}<<HOST>>${NC}.$NAMESPACE.env charts/$APP\n"

echo
printf "${WARNING}To check your deployment config:${NC}\n"
# $NAMESPACE must be included in metadata/namespace AND metadata/selfLink
# $BRANCH must be inclued in spec/template/spec/image
echo "  kubectl --context $CONTEXT -n $NAMESPACE edit deployment $app"

echo
printf "${WARNING}To view application logs:${NC}\n"
printf "  stern --context $CONTEXT --namespace $NAMESPACE -l app=$app --tail 100 | grep ${WARNING}<<search term>>${NC}\n"

echo
printf "${WARNING}To edit your namespace:${NC}\n"
echo "  kubectl --context $CONTEXT edit ns $NAMESPACE"

popd > /dev/null
