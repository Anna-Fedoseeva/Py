FROM python:3.11

RUN mkdir app
COPY app app
RUN ls -l

WORKDIR /app

RUN pip install -r requirements.txt

CMD ["python", "app.py"]
