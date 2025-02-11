  cd /home/bin/esp32
  echo "-1-"
  ls
  mv /home/bin/esp32/"${1}".ino /home/bin/esp32/esp32.ino
  echo "-2-"
  ls
  case $2 in
	  "esp32:esp32:stamp-s3")   	
               arduino-cli compile -b esp32:esp32:stamp-s3  --build-property  " build.extra_flags= -D ESP32 -D ARDUINO_USB_MODE=1 -D ARDUINO_USB_CDC_ON_BOOT=1"  --output-dir /home/bin/esp32 -e -vls
          ;;
  esac
  echo "-3-"
  ls
  mv /home/bin/esp32/esp32.ino /home/bin/esp32/"${1}".ino    
  echo "-4-"
  ls
  mv /home/bin/esp32/esp32.ino.bin /home/bin/esp32/"${1}".bin
  echo "-5-"
  ls
  cd ..
  