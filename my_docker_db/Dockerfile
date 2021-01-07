FROM python:3.5-slim-buster

ADD mockupmongo.py /

RUN mkdir /MockupFolder

COPY MockupFolder /MockupFolder

RUN pip3 install git+https://github.com/Luke2691/mongo-mockup-db

RUN pip3 install pymongo==3.4.0 python-dateutil

EXPOSE 27017

CMD ["python3", "-u", "mockupmongo.py"]
