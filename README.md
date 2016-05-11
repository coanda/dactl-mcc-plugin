## Dactl Plugin for Measurement Computing USB01208FS

This plugin is an interface between [Dactl](https://github.com/coanda/dactl/)
and the [Measurement Computing USB-1208FS](http://www.mccdaq.com/).

### Installation

1. Install [Dactl](https://github.com/coanda/dactl/)
2. Install MCCLIBUSB from ftp://lx10.tx.ncsu.edu/pub/Linux/drivers/USB/
3. Install [mcc-vapi](https://github.com/coanda/mcc-vapi)
4. Install this plugin using the commands: <br><br>
   `git clone https://github.com/coanda/dactl-mcc-plugin` <br>
   `cd dactl-mcc-plugin` <br>
   `./autogen.sh` <br>
   `make && sudo make install`

### Configuration

For a working configuration see this [example](https://github.com/coanda/dactl-mcc-config).

### Usage

After copying the example configuration it can be used by:

  > ```bash
dactl -f /path/to/file/configuration.xml
```
