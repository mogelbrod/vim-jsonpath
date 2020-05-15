#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

t() {
  expected="${@:$#}"
  args="${@:1:($#-1)}"
  echo -e "\n./jsonpath.py $args"
  output=$(time -p ./jsonpath.py $args)
  if [ "$output" = "$expected" ]; then
    echo -e "${GREEN}- pass${NC}"
  else
    echo -e "${RED}- ${expected}${NC}"
    echo -e "${RED}+ ${output}${NC}"
  fi
}

# Find path at offset
t tests/object.json -l 0 "first"
t tests/object.json -l 3:9 "first.second"
t tests/object.json -l 5:6 "first.second"
t tests/array.json -l 0 "0"
t tests/array.json -l 4 "2"
t tests/array.json -l 4:6 "2.index"
t tests/array.json -l 4:27 "2.value"
t tests/array.json -l 5:44 "3.numbers.0"
t tests/restcountries.json -l 17806:18 "219.capital"
t tests/restcountries.json -l 6963:8 "85.latlng.0"
t tests/unicode.json -l 1:27 "emoji"
t tests/unicode.json -l 1:38 "👍"

# Find offset for path
t tests/object.json "first" "2:12"
t tests/object.json "first.second" "3:15"
t tests/array.json "0" "2:3"
t tests/array.json "2" "4:3"
t tests/array.json "2.index" "4:14"
t tests/array.json "2.value" "4:26"
t tests/array.json "3.numbers.0" "6:5"
t tests/restcountries.json "219.capital" "17806:13"
t tests/restcountries.json "85.latlng.0" "6963:4"
t tests/unicode.json "👍" "1:34"
