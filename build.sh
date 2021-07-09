#!/bin/bash

# Constants
SIGNING_IDENTITY="iPhone Distribution: Hitinder Bawani (FNMD2QVA69)"
PROJECT_NAME="WaselDelivery"
ARCHIVE_NAME="WaselDelivery"
BUILD_TYPE="Hockey"
BUILD_DIR="$(pwd)/build"
# To make xcpretty work
export LC_ALL=en_US.UTF-8


# Build the project
xcodebuild  -workspace "${PROJECT_NAME}.xcworkspace" \
            -scheme "${PROJECT_NAME}" \
            -sdk iphoneos -configuration "${BUILD_TYPE}" clean archive \
            -archivePath "${BUILD_DIR}/${ARCHIVE_NAME}.xcarchive" | xcpretty -s
echo $?
if [ $? == 0 ]; then
# Archive
xcodebuild -exportArchive -archivePath "${BUILD_DIR}/${ARCHIVE_NAME}.xcarchive" \
            -exportOptionsPlist exportOptions.plist \
            -exportPath "${BUILD_DIR}" -configuration CODE_SIGN_IDENTITY=${SIGNING_IDENTITY} | xcpretty -s
            
# Remove Archive
rm -rf "${BUILD_DIR}/${ARCHIVE_NAME}.xcarchive"
exit 0;
fi
exit 1;
