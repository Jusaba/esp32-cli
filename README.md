

# Programacion de **esp32** con arduino-cli

 Esta imagen se ha creado para poder implementar compilación automática en Actions para compilar nuevas versiones de un skecthesp32 y distribuirlas a los dispositivos conectados a Serverpic.
 
 El primer dispositivo añadido al sistema es el M5Dial con un ESP32 STAMP-S3

# Versiones

1.0 esp32:esp32@2.0.11

    Este **core** admmite STAMP-S3, se ha comprobado que versiones posterires ( en alguna 3.0 ) no admite este procesador por lo que de momento 
    para poder utilizar M5Stack Dial es necesario utilizar el core cargado porque se ha comprobado compatibilidad.


### Pre-requisitos 📋
---
Al instalar **Arduno-cli** en linux en **/home/bin** se crea una estructura de carpetas que tenemos que tener en cuenta para construir la imagen

```
├─── root
│     ├─── Arduino
│     │       └─── libraries
│     └─── .arduino15
│               ├─── packages
│               ├─── staging
│               .
│               .
│               └─── logs
.
.
└─── home
       └─── bin
              └─── <WORKDIR>
 ```
**WORKDIR** es el directorio donde esta el **sketch** a compilar y, ambos, Directorio y Sketch deben tener el mismo nombre. Teniendo esto en cuenta, a la hora de crear la imagen crearemos el directorio de trabajo con el nombre de **esp32**. A la hora de compilar, depositaremos el **skecht** en ese directorio y lo renombraremos como **esp32.ino**.

## Como se ha construido la imagen 🛠️

La imagen se ha creado mediante el siguiente **Dockerfile**

```
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

```

La imagen esta creada sobre Debian, en primer lugar se instala **curl** para poder descargar seguidamente **python3** y **arduino-cli**. En el directorio /root/.arduino15/ de la imagen tenemos que incorporar el fichero **arduino-cli.yaml** con la información para descargar los packages de esp32, para eso, debemos dejar en el directorio donde se ejecuta el Dockerfile el fichero **arduino-cli.yaml** con el siguiente contenido

```
board_manager:
  additional_urls:
  - https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
daemon:
  port: "50051"
directories:
  data: /root/.arduino15
  downloads: /root/.arduino15/staging
  user: /root/Arduino
logging:
  file: ""
  format: text
  level: info

```

Solo contemplamos los packages de **esp32** por que son lo que en principio se van a utilizar. Si se necesitaran otros packages, se podria crear una nueva imagen actulizando este fichero. 

Luego, establecemos el path **/home/bin** como directorio de trabajo. 

En ese directorio  copiaremos el fichero bash **Compila.sh** que es el que realmente llama al compilador y que deberemos tener en el diretorio donde se encuentre el Dockerfile para crear la imagen.

Inmediatamente después creamos el directorio **esp32** que usaremos como volumen imagen de la carpeta con el **sketch** a compilar.  

Volviewndo a **Compila.sh**, es un bash  muy básico. Para ejecutarlo se le deben pasar dos parametros, el nombre del **sketch** original y el **fqbn** corrspondiente al modelo de esp utilizado. Con estos parametros, el bash,  renombra el **sketch** como **esp32.ino** y  llama al compilador con el **fqbn** que se precisa. Una vez finalizada la compilación se vuelve a poner el nombre original al **sketch** y al fichero **bin** resultado de la compilación.

El codigo de Compila.sh es el siguiente

```
  cd /home/bin/esp32
  mv /home/bin/esp32/"${1}".ino /home/bin/esp32/esp32.ino                                   #Renombramos el skecht como esp32.ino
  case $2 in
	  "esp32:esp32:stamp-s3")   	
               # Se define ESP32 para que el codigo sepa que esta compilando para ESP32
               # Se define ARDUINO_USB_MODE=1 y ARDUINO_USB_CDC_ON_BOOT=1 para que ESP32-S3 imprima por el puerto seriel	
               # Dejamos el archivo binario en la carpeta /home/bin/esp32
               arduino-cli compile --output-dir . --fqbn esp32:esp32:stamp-s3 -e -vls
          ;;
  esac
  mv /home/bin/esp32/esp32.ino /home/bin/esp32/"${1}".ino                                  #Restauramos el nombre original
  mv /home/bin/esp32/esp32.ino.bin /home/bin/esp32/"${1}".bin                              #Renombramos el bin con el nombre original
  cd ..
```
Continuando con el **Dockerfile**, una vez copiado el fichero **Compila.sh**, se ejecutan cuatro comandos de arduino-cli para que se creen las estructuras de directorios y se cargen los packages de esp32 y la vesriosn deseada

```
RUN arduino-cli lib list
RUN arduino-cli core update-index
RUN arduino-cli core install esp32:esp32@2.0.11
```
Por último, fijamos la entrada al contenedor con la llamada a **Compila.sh** pasandole los dos parametrosa mencionados.

```
ENTRYPOINT /bin/bash /home/bin/Compila.sh  $_ino $_fqbn

```

El Dockerfile lo ejecutamos como es costumbre

```
docker image build -t jusaba/esp32_cli:<Tag> .
```

Para subir la imagen a **Docker Hub**

```
docker push jusaba/esp32_cli:<Tag>
```

Evidentemente, antes debe hacer **login** en **Docker Hub**

```
docker login -u "jusaba" -p "<PASSWEORD>" docker.io 
```

### Instalación 🔧
---
_Para descargar la imagen_


```
docker push jusaba/esp32_cli:latest
```
## Ejecutando el compilador ⚙️
---
Supongamos que estamos en el directorio de la máquina local /home/serverpic y tenemos un programa M5StackDial.ino que queremos compilar y que este programa, ademas de las librerias **serverpic**,   necesita las librerias **AsyncTC**, **ESPAsyncWebServer**, **M5GFX**, **M5Unified**, **esp32-http-update-master**, **DFRobot_SHT20-master**, **M5Dial-master** y **M5Stack**. 

Las librerias las dejaremos en  en el directorio  **/home/serverpic/Librerias** y al ejecutar el contenedor, crearemos un volumen para asociar ese directorio a **/root/Arduino/libraries** y el directorio de trabajo **/home/serverpic**, con otro volumen lo asociaremos a **/home/bin/esp32**.

Supongamos igualmente que vamos a utilizar un M5 Dial que necesita las siguientes caracteeristicas del Esp32

| Descipcion | Valor |
| ------ | ------ |
| Placa | STAMP-S3 |


En este modelo no se necesitan muchas variables pero puede ser que otros modelos necesiten mas parametros por lo que optamos por incluirlas en el fichero **parametros.env** que crearemos en el directorio de trabajo. Ese fichero, en este ejemplo tendrá el siguiente contenido

```
_ino=M5StackDial
_fqbn=esp32:esp32:stamp-s3
```

Ya estamos en disposición de compilar

Ejecutar el contenedor de la siguiente forma.

```
docker run -v /home/serverpic/Librerias:/root/Arduino/libraries  -v /home/serverpic:/home/bin/esp32 --env-file parametros.env  -i jusaba/esp32-cli:latest 
``` 

Tras unos minutos de trabajo, en el direcotrio **/home/serverpic** nos encontraremos con el fichero compilado **M5StackDial.bin**




## Contribuyendo 🖇️


## Wiki 📖


## Versionado 📌

Usamos [SemVer](http://semver.org/) para el versionado. Para todas las versiones disponibles, mira los [tags en este repositorio](https://github.com/tu/proyecto/tags).

## Autores ✒️


* **Julián Salas Barolome** Desarrollo y documentación



## Licencia 📄

Este proyecto es libre para utilizarlo en Serverpic

## Expresiones de Gratitud 🎁

* Comenta a otros sobre este proyecto 📢
* Invita una cerveza 🍺 o un café ☕ a alguien del equipo. 
* Da las gracias públicamente 🤓.
* etc.



---
⌨️ La presentación de esta documentación ha sido posible gracias a  [Villanuevand](https://github.com/Villanuevand) 😊