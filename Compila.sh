  cd /home/bin/esp32
  mv /home/bin/esp32/"${1}".ino /home/bin/esp32/esp32.ino
  case $2 in
	  "esp32:esp32:stamp-s3")   	
               arduino-cli compile -b esp32:esp32:stamp-s3  --build-property  " build.extra_flags= -D ESP32 -D ARDUINO_USB_MODE=1 -D ARDUINO_USB_CDC_ON_BOOT=1"  -e -vls
          ;;
  esac
  mv /home/bin/esp32/esp32.ino /home/bin/esp32/"${1}".ino    
  mv /home/bin/esp32/esp32.ino.bin /home/bin/esp32/"${1}".bin
  cd ..
  