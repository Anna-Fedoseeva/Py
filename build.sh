#!/bin/bash

cd base
python3 base_cr.py
python3 run_num_upd.py
cd ..
docker-compose build
docker-compose up
