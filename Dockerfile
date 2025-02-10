FROM debian

ENV DIRPATH /home
WORKDIR $DIRPATH
RUN cd /home
RUN apt-get update
RUN cd /home
RUN apt-get install curl -y

RUN apt install python3 -y
RUN apt install python3-serial
RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

COPY arduino-cli.yaml /root/.arduino15/

ENV DIRPATH /home/bin
WORKDIR $DIRPATH
ENV PATH="$PATH:/home/bin"
COPY  Compila.sh  /home/bin
RUN mkdir esp32
RUN cd /home/bin/esp32

RUN arduino-cli lib list
RUN arduino-cli core update-index
RUN arduino-cli core install esp32:esp32@2.0.11

ENTRYPOINT /bin/bash /home/bin/Compila.sh  $_ino $_fqbn
