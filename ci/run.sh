#!/bin/bash

heading() {
  echo ""
  echo -e "\033[0;35m** ${*} **\033[0m"
  echo ""
}

fail() {
  >&2 echo "error: $@"
  exit 1
}

xcb() {
  LOG="$1"
  heading "$LOG"
  shift
  export NSUnbufferedIO=YES
  set -o pipefail && xcodebuild \
    -workspace SPTPersistentCache.xcworkspace \
    -UseSanitizedBuildSystemEnvironment=YES \
    -derivedDataPath build/DerivedData \
    CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
    "$@" | xcpretty || fail "$LOG failed"
}

if [[ -n "$TRAVIS_BUILD_ID" || -n "$GITHUB_WORKFLOW" ]]; then
  heading "Installing Tools"
  gem install xcpretty cocoapods
  export IS_CI=1
fi

heading "Linting Podspec"
pod spec lint SPTPersistentCache.podspec --quick || \
  fail "Podspec lint failed"

heading "Validating License Conformance"
git ls-files | egrep "\\.(h|m|mm)$" | \
  xargs ci/validate_license_conformance.sh ci/expected_license_header.txt || \
  fail "License Validation Failed"

#
# BUILD LIBRARIES
#

build_library() {
  xcb "Build Library [$1]" \
    build -scheme SPTPersistentCache \
    -sdk "$1" \
    -configuration Release
}

build_library macosx
build_library iphoneos
build_library iphonesimulator
build_library appletvos
build_library appletvsimulator
build_library watchos
build_library watchsimulator

#
# BUILD FRAMEWORKS
#

build_framework() {
  xcb "Build Framework [$1 for $2]" \
    build -scheme "$1" \
    -sdk "$2" \
    -configuration Release
}

build_framework SPTPersistentCache-OSX macosx
build_framework SPTPersistentCache-iOS iphoneos
build_framework SPTPersistentCache-iOS iphonesimulator
build_framework SPTPersistentCache-TV appletvos
build_framework SPTPersistentCache-TV appletvsimulator
build_framework SPTPersistentCache-Watch watchos
build_framework SPTPersistentCache-Watch watchsimulator

#
# BUILD DEMO APP
#

xcb "Build Demo App for Simulator" \
  build -scheme "SPTPersistentCacheDemo" \
  -sdk iphonesimulator \
  -configuration Release

#
# RUN TESTS
#

xcb "Run tests for macOS" test \
  -scheme "SPTPersistentCache" \
  -enableCodeCoverage YES \
  -sdk macosx

LATEST_IOS_RUNTIME=`xcrun simctl list runtimes | egrep "^iOS" | sort | tail -n 1 | awk '{print $NF}'`
IOS_UDID=`xcrun simctl create ios-tester com.apple.CoreSimulator.SimDeviceType.iPhone-8 "$LATEST_IOS_RUNTIME"`

xcb "Run tests for iOS" test \
  -scheme "SPTPersistentCache" \
  -enableCodeCoverage YES \
  -destination "platform=iOS Simulator,id=$IOS_UDID"

LATEST_TVOS_RUNTIME=`xcrun simctl list runtimes | egrep "^tvOS" | sort | tail -n 1 | awk '{print $NF}'`
TVOS_UDID=`xcrun simctl create tvos-tester com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p "$LATEST_TVOS_RUNTIME"`

xcb "Run tests for tvOS" test \
  -scheme "SPTPersistentCache" \
  -enableCodeCoverage YES \
  -destination "platform=tvOS Simulator,id=$TVOS_UDID"

#
# CODECOV
#

# output a bunch of stuff that codecov might recognize
if [[ -n "$GITHUB_WORKFLOW" ]]; then
  PR_CANDIDATE=`echo "$GITHUB_REF" | egrep -o "pull/\d+" | egrep -o "\d+"`
  [[ -n "$PR_CANDIDATE" ]] && export VCS_PULL_REQUEST="$PR_CANDIDATE"
  export CI_BUILD_ID="$RUNNER_TRACKING_ID"
  export CI_JOB_ID="$RUNNER_TRACKING_ID"
  export CODECOV_SLUG="$GITHUB_REPOSITORY"
  export GIT_BRANCH="$GITHUB_REF"
  export GIT_COMMIT="$GITHUB_SHA"
  export VCS_BRANCH_NAME="$GITHUB_REF"
  export VCS_COMMIT_ID="$GITHUB_SHA"
  export VCS_SLUG="$GITHUB_REPOSITORY"
fi

curl -sfL https://codecov.io/bash > build/codecov.sh
chmod +x build/codecov.sh
[[ "$IS_CI" == "1" ]] || CODECOV_EXTRA="-d"
build/codecov.sh -D build/DerivedData -X xcodellvm $CODECOV_EXTRA
