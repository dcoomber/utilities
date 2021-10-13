#!/bin/bash

APP_NAME=freeplane
APP_VER=1.9.10
APP_ARCH=linux-x64
BASE_URL=https://sourceforge.net/projects/freeplane/files/freeplane%20stable/archive/${APP_VER}
FILE_NAME=${APP_NAME}_bin-${APP_VER}.zip
DOWNLOAD_URL=${BASE_URL}/${FILE_NAME}
LAUNCHER=/home/${USER}/Desktop/${APP_NAME}-${APP_VER}.desktop
ICON_DIR_SOURCE=/opt/${APP_NAME}-${APP_VER}/${APP_NAME}.png
ICON_DIR_TARGET=/usr/share/icons/${APP_NAME}.png

# printf formatting
RED='\033[1;31m'    # Brown/Orange
YELLOW='\033[1;33m' # Yellow
NC='\033[0m'        # No Color

printf "${RED}Installing '%s'${NC}\n" "${APP_NAME}"

# Ensure working directory exists
if [ ! -d "${APP_NAME}" ]; then
    printf "${YELLOW}Creating directory '%s'.${NC}\n" "${APP_NAME}"
    mkdir ${APP_NAME} || exit 1
fi

# Move to working directory
pushd "${APP_NAME}" > /dev/null || exit

# Download the archive if it doesn't already exist
if [ ! -f "${FILE_NAME}" ]; then
    printf "${YELLOW}Downloading archive '%s'.${NC}\n" "${FILE_NAME}"
    wget $DOWNLOAD_URL || exit 1
fi

# Uncompress the archive
printf "${YELLOW}Expanding archive '%s'.${NC}\n" "${FILE_NAME}"
if [ -f "${FILE_NAME}" ]; then
    unzip -o "${FILE_NAME}" > /dev/null || exit 1
else
    # shellcheck disable=SC2059
    printf "${RED}Could not find the downloaded archive.${NC}\n"
    exit 1
fi

# Move the archive to opt directory
if [ -d "${APP_NAME}-${APP_VER}" ]; then
    printf "${YELLOW}Moving '%s-%s' to /opt.${NC}\n" "${APP_NAME}" "${APP_VER}"

    # Delete the target directory
    sudo rm -rf "/opt/${APP_NAME}-${APP_VER}"
    
    # Move the expanded directory
    sudo mv "${APP_NAME}-${APP_VER}" /opt/ && sudo chown -R "${USER}":"${USER}" "/opt/${APP_NAME}-${APP_VER}"

    # Copy the icon for later use
    sudo cp "${ICON_DIR_SOURCE}" "${ICON_DIR_TARGET}"
else
    # shellcheck disable=SC2059
    printf "${RED}Something went wrong when expanding the archive.${NC}\n"
    exit 1
fi

# Create launcher to menu
# shellcheck disable=SC2059
printf "${YELLOW}Creating launcher on your desktop.${NC}\n"
rm -rf "${LAUNCHER}"
touch "${LAUNCHER}" && chmod +x "${LAUNCHER}"

{
    echo "[Desktop Entry]"
    echo "Version=1.0"
    echo "Name=${APP_NAME} ${APP_VER}"
    echo "GenericName=Free mind mapping and knowledge management software"
    echo "Comment=Freeplane is a free and open source software application that supports thinking, sharing information and getting things done at work, in school and at home. The software can be used for mind mapping and analyzing the information contained in mind maps. Freeplane runs on any operating system that has a current version of Java installed. It can be run locally or portably from removable storage like a USB drive."
    echo "Exec=/opt/${APP_NAME}-${APP_VER}/${APP_NAME}.sh"
    echo "Icon=${ICON_DIR_TARGET}"
    echo "StartupNotify=true"
    echo "Terminal=false"
    echo "Type=Application"
    echo "Categories=Office;"
    echo "Keywords=mindmapping;flowcharts;education;development"
} > "${LAUNCHER}"

# cp launcher to menu
# shellcheck disable=SC2059
printf "${YELLOW}Copying desktop launcher to system menu.${NC}\n"
sudo cp "${LAUNCHER}" "/usr/share/applications/"

popd > /dev/null || exit
