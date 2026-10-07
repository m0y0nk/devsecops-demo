FROM python:3.12-alpine3.22

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apk upgrade --no-cache

COPY requirements.txt .

RUN python -m pip install --no-cache-dir --no-compile -r requirements.txt

COPY app ./app

USER 10001:10001

EXPOSE 5001

CMD ["python", "app/app.py"]