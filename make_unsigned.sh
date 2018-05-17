#!/bin/bash


xcodebuild clean CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO archive -scheme MSIReader -configuration MSIReader -archivePath MSIReader.xcarchive

xcodebuild -exportArchive -archivePath ./MSIReader.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath .
