#!/bin/bash
export MIX_ENV=prod
git pull
mix compile --force

