# --------------------------------------------------------------
# Welcome to your emonPi/emonBase
# --------------------------------------------------------------

This image was built using the EmonScripts installation scripts:
https://github.com/openenergymonitor/EmonScripts

You can find the emonSD software stack installed in the following primary locations:

# /opt/openenergymonitor
Contains software installed from github.com/openenergymonitor.
Including: EmonScripts, emonpi, emonhub, RFM2Pi & avrdude

# /opt/emoncms/modules
Contains symlinked emoncms modules installed from github.com/emoncms
Including: demandshaper, sync, backup, postprocess, usefulscripts

# /var/www/emoncms
Contains the emoncms web application and modules installed directly

# /var/opt/emoncms
Contains emoncms feed data, including PHPFina & PHPTimeSeries
