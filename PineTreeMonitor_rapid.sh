#!/bin/bash
#Dev Version:1.2
# Define bash Colours for better debug output
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White
NC='\033[0m'            # No Color


#Deine server properties for rpi-ws2812-server instance
IP=10.10.10.42 #IPv4 Address of server (hostname may work?)
PORT=6969      #Server port used when starting server (flag: -tcp $PORT)

#Should call script on pi over ssh to start the server on defined port, could be a single line but should be a script to verify not already running (wrap in tmux)

#Define the LED strip configuration
CHANNEL=1     #maximum channels looks to be 2? must be seperate channel from other server instance, PWM1 cannot be on channel 1
LEDNUM=144    #define number of LEDs being controlled by this server instance
DIRECT=0      #define direction of LED string, some testing showed anything but 0 causes crash or failure in init, further testing required
BRIGHT=64     #define brightness rnage 1-255, 32 or 64 seems to be good above 64 LEDs start getting hot. 255/undefined, LEDs, wiring, barrel plug get HOT! (55W per string, 11amp)
PIN=12        #define GPIO pin in use for LED data. PWM0 on Pi3B(+) either GPIO12(physical pin 32) or GPIO18(physical pin 12 ugh). PWM1 on Pi3B(+) GPIO13(physical pin 33)

SERV="$IP""/""$PORT"
FACE=$(ip route get 8.8.8.8 | head -n1 | awk '{print $5}') #define the interface to run tcpdump on, defaults to finding "default route"/external interface

SETUP="setup "$CHANNEL","$LEDNUM",3,"$DIRECT","$BRIGHT","$PIN";" #defines the setup command, hard coded LED type, FIX LATER PLEASE!

exec 3<>/dev/tcp/$SERV #Open TCP conneciton to server, should have an exception handler, FIX LATER PLEASE!

#Setup server and lights
echo "$SETUP" 1>&3                  #Send the setup command
echo "init;" 1>&3                   #Send init, this is where server will error or segfault if something is wrong, don't know if we can get this output and handle the exception
echo "fill $CHANNEL,000000;" 1>&3    #Fill the string buffer with off LEDs
echo "render;" 1>&3 #renders the lights buffer to LED string

tcpdump -nnvvvi $FACE not port 22 and not port $PORT | while read b; do #Main loop runs every packet caught by TCPdump, ignores 22 and own application port (some verbosity required for protocol, added all the verbosity)
    LEN_BR=$(echo $b | awk '{ print $17 }' ) #get the length value from tcpdump output

    if [ !  -z "$LEN_BR" ]; then #check if value existed/was pulled (arp doesn't have it as an example)
        LEN="${LEN_BR//)}" #remove the trailing ')' that was pulled

        echo $LEN #debug output of length
        case $(( $LEN / 500 )) in #divide length by 500, assuming MTU of 1500 this will create 3  whole values 0,1,2
          0 ) #for less then 500 bites render green LED
            if [[ "$c" == "0" ]]; then #Checks for 2 Same Colour in a row
              echo "rotate $CHANNEL,1,1,000000;" 1>&3
              echo " "
            fi
            echo -e "${Green}Green${NC}" #Console Colour output, in green
            echo "rotate $CHANNEL,1,1,00FF00;" 1>&3
            echo "render;" 1>&3
            c="0"
          ;;
          1) #for 500 -1000 bites render red LED, least common
            if [[ "$c" == "1" ]]; then
              echo "rotate $CHANNEL,1,1,000000;" 1>&3
              echo " "
            fi
            echo -e "${Red}Red${NC}"
            echo "rotate $CHANNEL,1,1,FF0000;" 1>&3
            echo "render;" 1>&3
            c="1"
          ;;
          2|3) #for over 1000 bites render white LED
            if [[ "$c" == "2" ]]; then #Checks for 2 Same Colour in a row
              echo "rotate $CHANNEL,1,1,000000;" 1>&3 #adds off LED to buffer to split up same colour to help show LEDs "rolling" along the string
              echo " " #prints empty line to console
            fi
            echo "White" #Console colour output
            echo "rotate $CHANNEL,1,1,FFFFFF;" 1>&3 #sends rotate to move all LEDs down string and adds white to start in buffer
            echo "render;" 1>&3 #renders the string
            c="2" #marks white(0) for dupe LED colour check
          ;;
        esac

    fi
done
