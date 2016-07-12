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

To run the application, run the command `mix run --no-halt` from the application root. It will shut itself down when all documents have been processed.
