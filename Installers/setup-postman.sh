#!/bin/bash

APP_NAME=Postman
APP_ARCH=linux64
DOWNLOAD_URL=https://dl.pstmn.io/download/latest/${APP_ARCH}
LAUNCHER=/home/${USER}/Desktop/${APP_NAME}.desktop
ICON=Postman/app/resources/app/assets/icon.png
ICON_DIR_SOURCE=/opt/${APP_NAME}/app/resources/app/assets/icon.png
ICON_DIR_TARGET=/usr/share/icons/${APP_NAME}Icon.png

# printf formatting
RED='\033[1;31m'    # Brown/Orange
YELLOW='\033[1;33m' # Yellow
NC='\033[0m'        # No Color

printf "${RED}Installing '$APP_NAME'${NC}\n"

# Ensure working directory exists
if [ ! -d "$APP_NAME" ]; then
    printf "${YELLOW}Creating directory '$APP_NAME'.${NC}\n"
    mkdir $APP_NAME || exit 1
fi

# Move to working directory
pushd "$APP_NAME" > /dev/null

# Download the archive if it doesn't already exist
if [ ! -f "${APP_ARCH}" ]; then
    printf "${YELLOW}Downloading latest version of '$APP_NAME'.${NC}\n"
    wget $DOWNLOAD_URL || exit 1
fi

# Uncompress the archive
printf "${YELLOW}Expanding archive '$APP_ARCH'.${NC}\n"
if [ -f "$APP_ARCH" ]; then
    tar -zxvf $APP_ARCH > /dev/null || exit 1
else
    printf "${RED}Could not find the downloaded archive.${NC}\n"
    exit 1
fi

# Move the archive to opt directory
if [ -d "${APP_NAME}" ]; then
    printf "${YELLOW}Moving '${APP_NAME}' to /opt.${NC}\n"

    # Delete the target directory
    sudo rm -rf "/opt/${APP_NAME}"
    
    # Move the expanded directory
    sudo mv "${APP_NAME}" /opt/ && sudo chown -R ${USER}:${USER} "/opt/${APP_NAME}"

    # Copy the icon for later use
    sudo cp "${ICON_DIR_SOURCE}" "${ICON_DIR_TARGET}"
else
    printf "${RED}Something went wrong when expanding the archive.${NC}\n"
    exit 1
fi

# Create launcher to menu
printf "${YELLOW}Creating launcher on your desktop.${NC}\n"
rm -rf "${LAUNCHER}"
touch "${LAUNCHER}" && chmod +x "${LAUNCHER}"

echo "[Desktop Entry]" >> "${LAUNCHER}"
echo "Name=${APP_NAME}" >> "${LAUNCHER}"
echo "Exec=/opt/${APP_NAME}/${APP_NAME}" >> "${LAUNCHER}"
echo "Comment=Postman is the collaboration platform for API development" >> "${LAUNCHER}"
echo "Terminal=false" >> "${LAUNCHER}"
echo "Icon=${ICON_DIR_TARGET}" >> "${LAUNCHER}"
echo "Type=Application" >> "${LAUNCHER}"
echo "Name[en_ZA]=${APP_NAME}" >> "${LAUNCHER}"

# cp launcher to menu
printf "${YELLOW}Copying desktop launcher to system menu.${NC}\n"
sudo cp "${LAUNCHER}" "/usr/share/applications/"

popd > /dev/null