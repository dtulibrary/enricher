use Mix.Config

config :enricher, getit_url: "http://localhost:3000?resolve"
config :enricher, institutional_holdings_url: "http://sfx.cvt.dk/sfx_local/cgi/public/get_file.cgi?file=institutional_holding.gzip"
# config :enricher, institutional_holdings_url: "http://localhost/institutional_holding.gzip"
