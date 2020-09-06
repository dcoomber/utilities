#!/bin/bash

APP_NAME=SweetHome3D
APP_VER=6.3
APP_ARCH=linux-x64
BASE_URL=https://sourceforge.net/projects/sweethome3d/files/${APP_NAME}/${APP_NAME}-${APP_VER}
FILE_NAME=${APP_NAME}-${APP_VER}-${APP_ARCH}.tgz
DOWNLOAD_URL=${BASE_URL}/${FILE_NAME}
LAUNCHER=/home/${USER}/Desktop/${APP_NAME}-${APP_VER}.desktop
ICON_DIR_SOURCE=/opt/${APP_NAME}-${APP_VER}/SweetHome3DIcon.png
ICON_DIR_TARGET=/usr/share/icons/SweetHome3DIcon.png

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
    tar -zxvf "${FILE_NAME}" > /dev/null || exit 1
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
    echo "GenericName=Interior 2D design application with 3D preview"
    echo "GenericName[de]=Innenraumplaner"
    echo "Comment=Interior design Java application for quickly choosing and placing furniture on a house 2D plan drawn by the end-user with a 3D preview"
    echo "Exec=/opt/${APP_NAME}-${APP_VER}/${APP_NAME}"
    echo "Icon=${ICON_DIR_TARGET}"
    echo "StartupNotify=true"
    echo "StartupWMClass=com-eteks-sweethome3d-SweetHome3D"
    echo "Terminal=false"
    echo "Type=Application"
    echo "Categories=Graphics;2DGraphics;3DGraphics;"
    echo "Keywords=interior;design;2D;3D;home;house;furniture;java;"
} > "${LAUNCHER}"

# cp launcher to menu
# shellcheck disable=SC2059
printf "${YELLOW}Copying desktop launcher to system menu.${NC}\n"
sudo cp "${LAUNCHER}" "/usr/share/applications/"

popd > /dev/null || exit