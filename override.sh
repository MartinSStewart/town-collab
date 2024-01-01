#!/bin/bash
set -ex

# The path where we'll do a clean checkout for the build system to ingest
rebuildPackZip() {
  # Remember our original location
  origin=`pwd`

  package=$1; version=$2

  cd ./overrides/packages/$package/$version
  rm -rf elm-stuff
  lamdera make
  cd ..
  rm pack.zip || true
  zip -r pack.zip $version/ -x "*/.git/*" -x "*/elm-stuff/*"

  # Generate our local override endpoint.json
  echo "{\"url\":\"https://static.lamdera.com/r/$package/pack.zip\",\"hash\":\"$(shasum pack.zip | cut -d' ' -f1)\"}" \
    > $version/endpoint.json

  # Go back to our original location
  cd $origin

}

# Reset our package cache so the compiler will fetch our newly packed packages
rm -rf ~/.elm

# Rebuild the pack.zip and endpoint.json for select overriden packages
rebuildPackZip "lamdera/codecs" "1.0.0"
rebuildPackZip "elm-explorations/webgl" "1.1.3"
LOVR="~/Desktop/town-collab/overrides"
EXPERIMENTAL=1
LDEBUG=1
rebuildPackZip "lamdera/program-test" "2.0.0"