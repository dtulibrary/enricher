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

To run the application, you will first need to set the url of the Solr that Enricher should query and update: `export SOLR_URL=http://localhost:8983`. The application will add `/solr/metastore/toshokan` or `/solr/metastore/update` to this url as appropriate. In dev mode it may be appropriate to run `iex -S mix` to launch a console. You can then trigger the update jobs manually using `Enricher.start_harvest(:full | :partial)`. A full run will update all relevant documents in the system while a partial run will only update documents coming from SFX and documents where `fulltext_availability_ss` is of type `UNDETERMINED`. In production mode, Enricher will schedule these jobs using the CRON scheduled defined in `config/prod.exs`. 

## System Design

The application uses the Elixir GenStage pattern. There are three stages, `HarvestStage`, `DeciderStage` and `UpdateStage`, each of which calls client code before handing its results to the next stage. Read the Elixir GenStage docs for more information about the pattern and the API.

## Concurrency

Of the three stages, only `HarvestStage` cannot be run concurrently. This is because it pages through a result set using a cursor. This cursor is maintained within the stage's state. In principle, there could be multiple instances of `DeciderStage` and `UpdateStage` running concurrently, to do this you would simply add multiple instances in the `Enricher.start_harvest\1` method, ensuring that all the `DeciderStage` instances subscribe to the same `HarvestStage`. However, the major bottleneck in the system is Solr. All stages use Solr in some way and increasing the level of concurrency will increase the level of Solr requests potentially leading to errors.

## Improvements

The application is not perfect, here are a number of potential areas for improvement:

  -  Use HTTP KeepAlive for all Solr requests to improve query performance.
  -  We should use ETS (Erlang Term Storage) for temporary storage of journal data to prevent duplicate Solr requests in the `DeciderStage`.
  -  `AccessDecider` could also check the open access DOI resolver for access information.
  -  We need to experiment more with concurrency to determine the maximum request level.
  -  At present, we use GenStage defaults (between 500 and 1000) for determining Solr query size and we commit updates after each batch. It may be appropriate to configure a larger batch size.
  -  GenStage Flow might be a more suitable design pattern.

## Build

Enricher uses Distillery as a build tool. To build a release, run `MIX_ENV=prod mix release --env=prod`. I am still in the process in working out the best practice for release management, so more precise instructions will follow.
