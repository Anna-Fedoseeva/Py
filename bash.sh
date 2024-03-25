#!/bin/bash

apt-get update
apt-get install -y python3 python3-pip

pip3 install flask pandas requests beautifulsoup4

touch parse_habr_hubs.py

cat <<EOF > parse_habr_hubs.py
from flask import Flask, jsonify
import pandas as pd
import requests
from time import sleep
from bs4 import BeautifulSoup
import sqlite3

app = Flask(__name__)

@app.route('/parse_habr_hubs')
def parse_habr_hubs():
    conn = sqlite3.connect('habr_hubs.db')
    cur = conn.cursor()

    cur.execute('''CREATE TABLE IF NOT EXISTS hubs (
                    name TEXT,
                    description TEXT,
                    rating TEXT,
                    subscribers TEXT,
                    link TEXT
                )''')

    for p in range(1, 12):
        url = f'https://habr.com/ru/hubs/page{p}/'
        r = requests.get(url)
        sleep(3)
        soup = BeautifulSoup(r.text, "html.parser")

        habs = soup.findAll('div', class_='tm-hubs-list__category-wrapper')
        for hab in habs:
            link = 'https://habr.com/ru/hubs/' + hab.find('a', class_='tm-hub__title').get('href')
            name = hab.find('a', class_='tm-hub__title').text
            description = hab.find('div', class_='tm-hub__description').text
            rating = hab.find('div', class_='tm-hubs-list__hub-rating').text
            subscribers = hab.find('div', class_='tm-hubs-list__hub-subscribers').text
            
            cur.execute("INSERT INTO hubs (name, description, rating, subscribers, link) VALUES (?, ?, ?, ?, ?)",
                        (name, description, rating, subscribers, link))

    conn.commit()
    conn.close()

    conn = sqlite3.connect('habr_hubs.db')
    df = pd.read_sql_query("SELECT * FROM hubs", conn)
    df_json = df.to_json(orient='records')
    conn.close()

    return jsonify(df_json)

if __name__ == '__main__':
    app.run(debug=True)
EOF

touch Dockerfile

cat <<EOF > Dockerfile
FROM python:3

COPY . /app
WORKDIR /app

RUN pip install flask pandas requests beautifulsoup4

CMD ["python", "parse_habr_hubs.py"]
EOF

touch docker-compose.yml

cat <<EOF > docker-compose.yml
version: "3.9"
services:
  parse-habr-hubs:
    build: .
EOF
