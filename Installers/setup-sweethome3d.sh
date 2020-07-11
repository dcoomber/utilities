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

printf "${RED}Installing '$APP_NAME'${NC}\n"

# Ensure working directory exists
if [ ! -d "$APP_NAME" ]; then
    printf "${YELLOW}Creating directory '$APP_NAME'.${NC}\n"
    mkdir $APP_NAME || exit 1
fi

# Move to working directory
pushd "$APP_NAME" > /dev/null

# Download the archive if it doesn't already exist
if [ ! -f "$FILE_NAME" ]; then
    printf "${YELLOW}Downloading archive '$FILE_NAME'.${NC}\n"
    wget $DOWNLOAD_URL || exit 1
fi

# Uncompress the archive
printf "${YELLOW}Expanding archive '$FILE_NAME'.${NC}\n"
if [ -f "$FILE_NAME" ]; then
    tar -zxvf $FILE_NAME > /dev/null || exit 1
else
    printf "${RED}Could not find the downloaded archive.${NC}\n"
    exit 1
fi

# Move the archive to opt directory
if [ -d "${APP_NAME}-${APP_VER}" ]; then
    printf "${YELLOW}Moving '${APP_NAME}-${APP_VER}' to /opt.${NC}\n"

    # Delete the target directory
    sudo rm -rf "/opt/${APP_NAME}-${APP_VER}"
    
    # Move the expanded directory
    sudo mv "${APP_NAME}-${APP_VER}" /opt/ && sudo chown -R ${USER}:${USER} "/opt/${APP_NAME}-${APP_VER}"

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
echo "Version=1.0" >> "${LAUNCHER}"
echo "Name=${APP_NAME} ${APP_VER}" >> "${LAUNCHER}"
echo "GenericName=Interior 2D design application with 3D preview" >> "${LAUNCHER}"
echo "GenericName[de]=Innenraumplaner" >> "${LAUNCHER}"
echo "Comment=Interior design Java application for quickly choosing and placing furniture on a house 2D plan drawn by the end-user with a 3D preview" >> "${LAUNCHER}"
echo "Exec=/opt/${APP_NAME}-${APP_VER}/${APP_NAME}" >> "${LAUNCHER}"
echo "Icon=${ICON_DIR_TARGET}" >> "${LAUNCHER}"
echo "StartupNotify=true" >> "${LAUNCHER}"
echo "StartupWMClass=com-eteks-sweethome3d-SweetHome3D" >> "${LAUNCHER}"
echo "Terminal=false" >> "${LAUNCHER}"
echo "Type=Application" >> "${LAUNCHER}"
echo "Categories=Graphics;2DGraphics;3DGraphics;" >> "${LAUNCHER}"
echo "Keywords=interior;design;2D;3D;home;house;furniture;java;" >> "${LAUNCHER}"

# cp launcher to menu
printf "${YELLOW}Copying desktop launcher to system menu.${NC}\n"
sudo cp "${LAUNCHER}" "/usr/share/applications/"

popd > /dev/null