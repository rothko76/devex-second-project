FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py /app

CMD ["python", "app.py"]



COPY app.py /app

RUN pip install flask

