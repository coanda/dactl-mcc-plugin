## Plugin README

README for plugin usb1208fs.

### Plugin XML Configuration

```xml
<plugins>
  <plugin id="usb1208fs0" type="usb1208fs">
    <ui:object id="usb1208fs-ctl0" type="plugin-control" parent="box0-0">
      <ui:property name="ref" device="usb1208fs">/ser0</ui:property>
    </ui:object>
  </plugin>
</plugins>
```

### Plugin CLD XML Configuration

```xml
<cld:objects>
  <cld:object id="ser0" type="port" ptype="serial">
    <cld:property name="device">/dev/ttyACM0</cld:property>
    <cld:property name="baudrate">9600</cld:property>
    <cld:property name="databits">8</cld:property>
    <cld:property name="stopbits">1</cld:property>
    <cld:property name="parity">None</cld:property>
    <cld:property name="handshake">Hardware</cld:property>
    <cld:property name="accessmode">Read and Write</cld:property>
    <cld:property name="echo">false</cld:property>
  </cld:object>
</cld:objects>
```
