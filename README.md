# Enricher

The purpose of this application is to update Metastore with fulltext availability data. Since this data is time-consuming to generate, Enricher is separated from the normal Metastore flow and runs in the background on a nightly basis.

## Logic

Enricher's decision making logic is illustrated in the attached flow chart. Basically there are two main sources of knowledge about access: 

  - Fulltext information is embedded within the document itself. In this case, Enricher can use this data to determine fulltext access.
  - Fulltext information is contained within SFX. In this case, Enricher looks ast the SFX data stored within Metastore and determines access rules based on this.

At present, access rules are limited to `dtu` and `dtupub`, meaning either DTU users or public users. Anything which `dtupub` has access to will also be accessible by `dtu`. 

## Installation

```bash
sudo apt-get update
sudo apt-get install -y wget
sudo wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb
sudo apt-get update
sudo apt-get install -y esl-erlang
sudo apt-get install -y elixir
mix deps.get
```

## Usage

To run the application, run `mix run --no-halt`. This will launch a web interface at `http://localhost:4001`. The interface controls the harvesting process. The following requests are permitted:

```
curl http://enricher.bla:4001/harvest/status # GET Gives information about the current job's progress
curl --data set=full --data endpoint=http://solr_url.bla:8983 http://enricher.bla:4001/harvest/create # POST Start a full harvest at the given endpoint
curl --data set=partial --data endpoint=http://solr_url.bla:8983 http://enricher.bla:4001/harvest/create # POST Start a partial harvest at the given endpoint
curl -X POST http://enricher.bla:4001/harvest/delete # POST Stops the current harvest job
```
There are two harvest modes, `full` and `partial`. `full` will update all articles and books within the given index, `partial` will only update those with a UNDETERMINED status and those that come from SFX. It is envisioned that `full` should be run infrequently as the non-SFX documents are unlikely to change regularly. `partial` should be run on a daily or weekly basis so that new documents are enriched and changes to SFX licenses are reflected promptly in the index.

## Helpers

To assist in debugging article access decisions, there are a couple of helper methods in the `Helpers` module you can use. To test a single access decision, use the following method, supplying the document's cluster id as an argument: `mix run -e "Helpers.test_article(2287274192)"`. To update a single document, use the `update_article\1` method in the same manner.

## System Design

The application uses the Elixir GenStage pattern. There are three stages, `HarvestStage`, `DeciderStage` and `UpdateStage`, each of which calls client code before handing its results to the next stage. Read the Elixir GenStage docs for more information about the pattern and the API.

## Concurrency

Of the three stages, only `HarvestStage` cannot be run concurrently. This is because it pages through a result set using a cursor. This cursor is maintained within the stage's state. Multiple instances of `DeciderStage` and `UpdateStage` can be run concurrently, the level of concurrency is determined by the number of instances created in the `Enricher.start_harvest\1` method. Note though that the major bottleneck in the system is Solr. Increasing the level of concurrency will increase the volume of Solr requests which has been a cause of errors in my tests.

## Caching

To cut down on the number of HTTP requests, we begin the Enrichment process by retrieving all journals that come from SFX and storing them in memory using [Erlang Term Storage](http://elixir-lang.org/getting-started/mix-otp/ets.html). This table will be dropped upon conclusion of the harvest method. 

## Improvements

The application is not perfect, here are a number of potential areas for improvement:

  -  ~~Use HTTP KeepAlive for all Solr requests to improve query performance.~~
  -  ~~We should use ETS (Erlang Term Storage) for temporary storage of journal data to prevent duplicate Solr requests in the `DeciderStage`.~~
  -  `AccessDecider` could also check the open access DOI resolver for access information.
  -  We need to experiment more with concurrency to determine the maximum request level.
  -  ~~At present, we use GenStage defaults (between 500 and 1000) for determining Solr query size and we commit updates after each batch. It may be appropriate to configure a larger batch size.~~
  -  GenStage Flow might be a more suitable design pattern.
  - We need to get a handle on release and deploy packaging.

## Build

Enricher uses Distillery as a build tool. To build a release, run `MIX_ENV=prod mix release --env=prod`. I am still in the process in working out the best practice for release management, so more precise instructions will follow.
