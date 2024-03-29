from flask import Flask, render_template
import pandas as pd
import requests
from time import sleep
from bs4 import BeautifulSoup
import sqlite3

app = Flask(__name__)

@app.route('/', methods=['GET'])
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

    for p in range(1, 5):
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
    conn.close()

    return render_template('table.html', table = df.to_html(index=False))

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=8000)
