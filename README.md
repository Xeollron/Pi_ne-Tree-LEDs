# Pi_ne-Tree-LEDs

Decorating a Christmas tree with network traffic from gateways/servers.
Shown on ws2812b LED strips running off a Raspberry Pi B3+ using Rpi-ws2812-server by tom-2015 (https://github.com/tom-2015/rpi-ws2812-server) built with jgarff's Pi PWM Driver (https://github.com/jgarff/rpi_ws281x).

Default setup uses Physical Pin 32 for primary strip data, Pin 33 for secondary strip data, and Pin 34 ground.

Using a constant tcpdump, the default outputs are
White for TCP SIN / SIN-ACK
Green for UDP
Red for ARP
As in lab testing this provided a decent balance of colours.

Using an 18inch tree and 2 High Density 144 LED ws2812b strips (http://a.co/d/eTvPFiq), a Pi 3B+, 4GB microSD and 50W 5V PSU (http://a.co/d/cnn7rRJ)
