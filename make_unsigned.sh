#!/bin/bash

xcodebuild clean CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO archive -scheme MSIReader -configuration MSIReader -archivePath MSIReader.xcarchive

xcodebuild -exportArchive -archivePath ./MSIReader.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath .

S3_NAME=s3://moven-app-builds-bca/MSIReader-unsigned-$(date -u +%Y%m%d-%H%M).ipa

aws --profile=am s3 cp MSIReader.ipa $S3_NAME

echo "INFO: IPA is uploaded as ${S3_NAME}"
