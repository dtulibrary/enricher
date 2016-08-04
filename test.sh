#!/bin/bash
## This test sets up a solr5 container based on the image specified
## and configures the Enricher container to run its tests against that container.
cd tmp
docker pull unstable.docker.cvt.dk:5000/dtu/solr_with_fixtures
docker run --rm=true -ti --name solr5 dtu/solr_with_fixtures:5.3 &
# Connect solr5 container to test container and run tests
cd ..
docker run --link solr5:http -e SOLR_URL=solr5:8983 enricher mix test
