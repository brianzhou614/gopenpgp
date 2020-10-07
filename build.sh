#!/bin/bash

PACKAGE_PATH="github.com/ProtonMail/gopenpgp"
cd "${GOPATH}"/src/${PACKAGE_PATH} || exit
if ! [ -L "v2" ]; then
  ln -s . v2
fi

printf "\e[0;32mStart installing vendor \033[0m\n\n"
GO111MODULE=on
go mod vendor
GO111MODULE=off
printf "\e[0;32mDone \033[0m\n\n"

OUTPUT_PATH="dist"

ANDROID_OUT=${OUTPUT_PATH}/"Android"
ANDROID_OUT_FILE_NAME="gopenpgp"
ANDROID_OUT_FILE=${ANDROID_OUT}/${ANDROID_OUT_FILE_NAME}.aar
ANDROID_JAVA_PAG="com.proton.${ANDROID_OUT_FILE_NAME}"

IOS_AND_SIM_OUT=${OUTPUT_PATH}/"iOS_and_Simulator"
IOS_AND_SIM_OUT_FILE_NAME="Crypto"
IOS_AND_SIM_OUT_FILE=${IOS_AND_SIM_OUT}/${IOS_AND_SIM_OUT_FILE_NAME}.framework

IOS_OUT=${OUTPUT_PATH}/"iOS"
IOS_OUT_FILE_NAME="Crypto"
IOS_OUT_FILE=${IOS_OUT}/${IOS_OUT_FILE_NAME}.framework

macOS_OUT=${OUTPUT_PATH}/"macOS"
macOS_OUT_FILE_NAME="Crypto"
macOS_OUT_FILE=${macOS_OUT}/${macOS_OUT_FILE_NAME}.framework

macOSUI_OUT=${OUTPUT_PATH}/"macOSUI"
macOSUI_OUT_FILE_NAME="Crypto"
macOSUI_OUT_FILE=${macOSUI_OUT}/${macOSUI_OUT_FILE_NAME}.framework

IOSSIM_OUT=${OUTPUT_PATH}/"iOS_Simulator"
IOSSIM_OUT_FILE_NAME="Crypto"
IOSSIM_OUT_FILE=${IOSSIM_OUT}/${IOSSIM_OUT_FILE_NAME}.framework

mkdir -p $ANDROID_OUT
mkdir -p $IOS_OUT
mkdir -p $macOS_OUT
mkdir -p $macOSUI_OUT
mkdir -p $IOSSIM_OUT

install() 
{
    INSTALL_NAME=$1
    FROM_PATH=$2
    INSTALL_PATH=$3
    if [[ -z "${INSTALL_PATH}" ]]; then
        printf "\e[0;32m ${INSTALL_NAME} project path is undefined! ignore this !\033[0m\n";
    else 
        printf "\n\e[0;32mDo you wise to install the library into ${INSTALL_NAME} project \033[0m\n"
        printf "\e[0;37m${INSTALL_NAME} Project Path: \033[0m" 
        printf "\e[0;37m${INSTALL_PATH} \033[0m" 
        printf "\n"
        while true; do
            read -p "[Yy] or [Nn]:" yn
            case $yn in
                [Yy]* )
                    printf "\e[0;32m  Installing .... \033[0m\n";
                    cp -rf ${FROM_PATH} ${INSTALL_PATH}/
                    printf "\n\e[0;32mInstalled \033[0m\n\n"
                    break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

# import function, add internal package in the build
import()
{
    PACKAGES=" ${PACKAGES} ${PACKAGE_PATH}/v2/$1"
}

external() 
{
    PACKAGES="${PACKAGES} $1"
}

######## MARK -- Main

#flags
DFLAGS="'all=-s -w'"

PACKAGES=""
#add internal package 
## crypto must be the first one, and the framework name better same with the first package name
import crypto 
import armor 
import constants 
import models 
import subtle 
import helper

## add external package
if [ "$1" != '' ]; then
  for ((i = 1; i <= $#; i++ )); do
    external ${!i}
  done
fi

printf "PACKAGES: ${PACKAGES}\n"
## start building

printf "\e[0;32mStart Building iOS framework .. Location: ${IOS_OUT} \033[0m\n\n"
## tags - mobile tag will filter unsupported functions  //ios macos macos-ui
gomobile bind -tags mobile -target ios -x -o ${IOS_AND_SIM_OUT_FILE} -ldflags="${DFLAGS}" ${PACKAGES}
# install iOS  ${IOS_OUT_FILE} ${IOS_PROJECT_PATH}

printf "\e[0;32mStart Building macOS framework .. Location: ${macOS_OUT} \033[0m\n\n"
gomobile bind -tags mobile -target macos -x -o ${macOS_OUT_FILE} -ldflags="${DFLAGS}" ${PACKAGES}

printf "\e[0;32mStart Building macOS-UI framework .. Location: ${macOSUI_OUT} \033[0m\n\n"
gomobile bind -tags mobile -target macos-ui -x -o ${macOSUI_OUT_FILE} -ldflags="${DFLAGS}" ${PACKAGES}

#printf "\e[0;32mStart Building Android lib .. Location: ${ANDROID_OUT} \033[0m\n\n"
#gomobile bind -tags mobile -target android -javapkg ${ANDROID_JAVA_PAG} -o ${ANDROID_OUT_FILE} -ldflags="${DFLAGS}" ${PACKAGES}
# install Android ${ANDROID_OUT} ${ANDROID_PROJECT_PATH}

printf "\e[0;32mInstalling frameworks. \033[0m\n\n"

printf "\e[0;32mAll Done. \033[0m\n\n"

cp -rL $IOS_AND_SIM_OUT_FILE $IOS_OUT_FILE;
cp -rL $IOS_AND_SIM_OUT_FILE $IOSSIM_OUT_FILE;

lipo $IOSSIM_OUT_FILE/Versions/A/Crypto -remove arm64 -output $IOSSIM_OUT_FILE/Versions/A/Crypto;
lipo $IOS_OUT_FILE/Versions/A/Crypto -remove x86_64 -output $IOS_OUT_FILE/Versions/A/Crypto;

XCFRAMEWORK_OUT_FILE=$OUTPUT_PATH/Crypto.xcframework
xcodebuild -create-xcframework  -framework $IOS_OUT_FILE  -framework $macOS_OUT_FILE -framework $macOSUI_OUT_FILE -framework $IOSSIM_OUT_FILE  -output $XCFRAMEWORK_OUT_FILE;
zip -r $XCFRAMEWORK_OUT_FILE.zip $XCFRAMEWORK_OUT_FILE;
