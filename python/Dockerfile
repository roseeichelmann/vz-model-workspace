FROM python:3.12-bullseye

RUN mkdir /application
WORKDIR /application

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

CMD [ "/bin/bash"]
