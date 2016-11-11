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

| Endpoint | Params | Description
| --- |:----:| ----- |
| GET /harvest/status | |  Gives information about the current job's progress, returns 202 if a job is in progress, 200 otherwise. Also available as JSON |
| POST /harvest/create | `mode=partial|full|sfx|no_access endpoint=solr_url` | Start a harvest at the given endpoint, returns 202 if job accepted, 503 if a job is already in progress, 400 if params are incorrect |
| POST /harvest/stop | | Stops the current harvest job, returns 204 if successful |
| GET /debug/article | |  Debugging interface for access decisions |
| GET /cache/update| |  Interface for updating the journal cache for use in debugging access decisions |

There are four harvest modes, `full`, `partial`, `sfx` and `no_access`.

  - `full` will update all articles and books within the given index, should be run infrequently as the non-SFX documents are unlikely to change regularly.
  - `partial` will only update those with an `UNDETERMINED` status, should be run on a daily basis so that new documents are enriched.
  - `sfx` will update all documents which have `fulltext_info_ss:sfx`, i.e. those that have fulltext access through SFX, should be run on a weekly basis so that changes to SFX licenses are reflected in the index.
  - `no_access` will update those documents with `fulltext_info:none`, i.e. those which have been assessed not to have accessible fulltext, should be run manually in response to changes in Enricher logic which have implications for documents that have already been processed (e.g. addition of new availability sources).

### Testing locally

If you have a Solr instance running locally you can test the whole Enricher flow locally:
```
curl -d 'mode=partial' -d 'endpoint=http://localhost:8983' http://localhost:4001/harvest/create
```

## Debugging Access Decisions

There is a web interface that you can use to debug Enricher's Access Decisions. This is available at `/debug/article`. Enter the cluster id of the article you want to debug and the endpoint of the relevant Solr index and it will print a summary of the relevant data. By default it will use the latest journal cache; if you want to use a new journal cache, you can refresh the cache at `/cache/update`.

## System Design

Enricher consists of a Plug based web interface and a number of GenServers to maintain state. The web interface can trigger a harvest job which is built using the Elixir GenStage pattern. There are three stages, `HarvestStage`, `DeciderStage` and `UpdateStage`, each of which calls client code before handing its results to the next stage. Read the [Elixir GenStage docs](https://hexdocs.pm/gen_stage/Experimental.GenStage.html) for more information about the pattern and the API. There is a HarvestManager server which maintains state about the current harvest and is accessed by many of the other components and a JournalCache server which maintains the cached SFX journal data.

## Concurrency

Of the three stages, only `HarvestStage` cannot be run concurrently. This is because it pages through a result set using a cursor. This cursor is maintained within the stage's state. Multiple instances of `DeciderStage` and `UpdateStage` can be run concurrently, the level of concurrency is determined by the number of instances created in the `Enricher.start_harvest\1` method. Note though that the major bottleneck in the system is Solr. Increasing the level of concurrency will increase the volume of Solr requests which has been a cause of errors in my tests.

## Caching

To cut down on the number of HTTP requests, we begin the Enrichment process by retrieving all journals that come from SFX and storing them in memory using [Erlang Term Storage](http://elixir-lang.org/getting-started/mix-otp/ets.html). This cache is regenerated at the beginning of each harvest.

## Improvements

The application is not perfect, here are a number of potential areas for improvement:

  -  ~~Use HTTP KeepAlive for all Solr requests to improve query performance.~~
  -  ~~We should use ETS (Erlang Term Storage) for temporary storage of journal data to prevent duplicate Solr requests in the `DeciderStage`.~~
  -  `AccessDecider` could also check the open access DOI resolver for access information.
  -  We need to experiment more with concurrency to determine the maximum request level.
  -  ~~At present, we use GenStage defaults (between 500 and 1000) for determining Solr query size and we commit updates after each batch. It may be appropriate to configure a larger batch size.~~
  -  GenStage Flow might be a more suitable design pattern.
  - We need to get a handle on release and deploy packaging.
  -  Provide information on batch size and estimated time of completion through the web interface.

## Build

Enricher uses Distillery as a build tool. To build a release, run `MIX_ENV=prod mix release --env=prod`. I am still in the process in working out the best practice for release management, so more precise instructions will follow.
