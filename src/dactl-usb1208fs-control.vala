using Mcc;
using LibUSB;

/**
 * User interface control for a Measurement Computing USB-1208FS Multifunction DAQ
 */
[GtkTemplate (ui = "/org/coanda/dactl/plugins/usb1208fs/usb1208fs-control.ui")]
public class Dactl.usb1208fs.Control : Dactl.SimpleWidget, Dactl.PluginControl, Dactl.CldAdapter {

    /* XML/XSD variables are useless for now */
    private string _xml = """
        <ui:object id=\"usb1208fs-ctl0\" type=\"usb1208fs-plugin\">
          <ui:property name="ref" device="usb1208fs">/ser0</ui:property>
        </ui:object>
    """;

    private string _xsd = """
        <xs:element name="object">
          <xs:attribute name="id" type="xs:string" use="required"/>
          <xs:attribute name="type" type="xs:string" use="required"/>
          <xs:attribute name="parent" type="xs:string" use="required"/>
        </xs:element>
    """;

    [GtkChild]
    private Gtk.Label lbl_usb1208fs;

    [GtkChild]
    private Gtk.ToggleButton btn_connect;

    [GtkChild]
    private Gtk.ToggleButton btn_acquire;

    [GtkChild]
    private Gtk.Image img_connect;

    [GtkChild]
    private Gtk.Image img_disconnect;

    [GtkChild]
    private Gtk.Image img_acquire;

    [GtkChild]
    private Gtk.Image img_stop;

    [GtkChild]
    private Gtk.ComboBoxText comboboxtext_serial_number;

    [GtkChild]
    private Gtk.ComboBoxText comboboxtext_input;

    [GtkChild]
    private Gtk.ComboBoxText comboboxtext_range;

    [GtkChild]
    private Gtk.Adjustment adjustment_output0;

    [GtkChild]
    private Gtk.Adjustment adjustment_output1;

    [GtkChild]
    private Gtk.Adjustment adjustment_rate;

    [GtkChild]
    private Gtk.Entry entry_input_value;

    [GtkChild]
    private Gtk.Expander expander_settings;

    [GtkChild]
    private Gtk.Expander expander_test;

    [GtkChild]
    private Gtk.RadioButton radiobutton_port_a_in;

    [GtkChild]
    private Gtk.RadioButton radiobutton_port_b_in;

    [GtkChild]
    private Gtk.Box box_port_a;

    [GtkChild]
    private Gtk.Box box_port_b;

    [GtkChild]
    private Gtk.Button btn_blink;

    [GtkChild]
    private Gtk.Entry entry_counter;

    /**
     * {@inheritDoc}
     */
    protected override string xml {
        get { return _xml; }
    }

    /**
     * {@inheritDoc}
     */
    protected override string xsd {
        get { return _xsd; }
    }

    public virtual string parent_ref { get; set; }

    private Gee.Set<string> chrefs;

    private Cld.AIChannel[] ai_channels;

    private Cld.AOChannel[] ao_channels;

    private Cld.DChannel[] dio_channels;

    private uint8 porta_direction;

    private uint8 portb_direction;

    private uint32 counter_value = 0;

    private uint32 counter_offset = 0;

    /**
     * {@inheritDoc}
     */
    protected bool satisfied { get; set; default = false; }

    /**
     * Data sampling rate [Hz]
     */
    private double _sampling_rate;
    public double sampling_rate {
        get { return _sampling_rate; }
        set { _sampling_rate = value; }
    }

    /**
     * Analog input sampling mode
     */
    private AcquisitionMode _acquisition_mode;
    public AcquisitionMode acquisition_mode {
        get { return _acquisition_mode; }
        set { _acquisition_mode = value; }
    }

    /**
     * The analog input acquisition mode
     * XXX Not impemented yet
     */
    public enum AcquisitionMode {
        SOFTWARE,
        HARDWARE;

        public string to_string () {
            switch (this) {
                case SOFTWARE: return "software";
                case HARDWARE:  return "hardware";
                default: assert_not_reached ();
            }
        }

        public static AcquisitionMode[] all () {
            return { SOFTWARE, HARDWARE };
        }

        public static AcquisitionMode parse (string value) {
            try {
                var regex_software = new Regex ("software", RegexCompileFlags.CASELESS);
                var regex_hardware = new Regex ("hardware", RegexCompileFlags.CASELESS);

                if (regex_software.match (value))
                    return SOFTWARE;
                else if (regex_hardware.match (value))
                    return HARDWARE;
            } catch (RegexError e) {
                warning ("Error %s", e.message);
            }

            /* XXX need to return something */
            return SOFTWARE;
        }
    }

    /**
     * Channel connections with names as given in the USB-1208FS Manual
     */
    public enum Connection {
        PORTA0, PORTA1, PORTA2, PORTA3, PORTA4, PORTA5, PORTA6, PORTA7, PORTB0,
        PORTB1, PORTB2, PORTB3, PORTB4, PORTB5, PORTB6, PORTB7, DAOUT0, DAOUT1,
        CH0_SE, CH1_SE, CH2_SE, CH3_SE, CH4_SE, CH5_SE, CH6_SE, CH7_SE, CH0_DIFF,
        CH1_DIFF, CH2_DIFF, CH3_DIFF;

        public static Connection[] all () {
            return { PORTA0, PORTA1, PORTA2, PORTA3, PORTA4, PORTA5, PORTA6,
                     PORTA7, PORTB0, PORTB1, PORTB2, PORTB3, PORTB4, PORTB5,
                     PORTB6, PORTB7, DAOUT0, DAOUT1, CH0_SE, CH1_SE, CH2_SE,
                     CH3_SE, CH4_SE, CH5_SE, CH6_SE, CH7_SE, CH0_DIFF, CH1_DIFF,
                     CH2_DIFF, CH3_DIFF };
        }

        public static Connection[] se_inputs () {
            return { CH0_SE, CH1_SE, CH2_SE, CH3_SE, CH4_SE, CH5_SE, CH6_SE,
                     CH7_SE };
        }

        public static Connection[] diff_inputs () {
            return { CH0_DIFF, CH1_DIFF, CH2_DIFF, CH3_DIFF };
        }

        public static Connection[] analog_outputs () {
            return { DAOUT0, DAOUT1 };
        }

        public static Gee.List<Connection> porta () {
            Connection[] items = { PORTA0, PORTA1, PORTA2, PORTA3, PORTA4,
                                                       PORTA5, PORTA6, PORTA7 };
            Gee.ArrayList<Connection> list = new Gee.ArrayList<Connection> ();
            for (int i = 0; i < items.length; i++)
                list.add (items[i]);

            return list;
        }

        public static Gee.List<Connection> portb () {
            Connection[] items = { PORTB0, PORTB1, PORTB2, PORTB3, PORTB4,
                                                       PORTB5, PORTB6, PORTB7 };
            Gee.ArrayList<Connection> list = new Gee.ArrayList<Connection> ();
            for (int i = 0; i < items.length; i++)
                list.add (items[i]);

            return list;
        }

        /**
         * @param value a named channel
         * @return a corresponding connection
         */
        public static Connection parse (string value) {
            switch (value) {
                case "PORT A0":      return PORTA0;
                case "PORT A1":      return PORTA1;
                case "PORT A2":      return PORTA2;
                case "PORT A3":      return PORTA3;
                case "PORT A4":      return PORTA4;
                case "PORT A5":      return PORTA5;
                case "PORT A6":      return PORTA6;
                case "PORT A7":      return PORTA7;
                case "PORT B0":      return PORTB0;
                case "PORT B1":      return PORTB1;
                case "PORT B2":      return PORTB2;
                case "PORT B3":      return PORTB3;
                case "PORT B4":      return PORTB4;
                case "PORT B5":      return PORTB5;
                case "PORT B6":      return PORTB6;
                case "PORT B7":      return PORTB7;
                case "DA OUT 0":     return DAOUT0;
                case "DA OUT 1":     return DAOUT1;
                case "CH 0 IN":      return CH0_SE;
                case "CH 1 IN":      return CH1_SE;
                case "CH 2 IN":      return CH2_SE;
                case "CH 3 IN":      return CH3_SE;
                case "CH 4 IN":      return CH4_SE;
                case "CH 5 IN":      return CH5_SE;
                case "CH 6 IN":      return CH6_SE;
                case "CH 7 IN":      return CH7_SE;
                case "CH 0 IN DIFF": return CH0_DIFF;
                case "CH 1 IN DIFF": return CH1_DIFF;
                case "CH 2 IN DIFF": return CH2_DIFF;
                case "CH 3 IN DIFF": return CH3_DIFF;
                default:             return PORTA0;
            }
        }

        /**
         * @return a string value that represents a connection
         */
        public string to_string () {
            switch (this) {
                case PORTA0:   return "PORT A0";
                case PORTA1:   return "PORT A1";
                case PORTA2:   return "PORT A2";
                case PORTA3:   return "PORT A3";
                case PORTA4:   return "PORT A4";
                case PORTA5:   return "PORT A5";
                case PORTA6:   return "PORT A6";
                case PORTA7:   return "PORT A7";
                case PORTB0:   return "PORT B0";
                case PORTB1:   return "PORT B1";
                case PORTB2:   return "PORT B2";
                case PORTB3:   return "PORT B3";
                case PORTB4:   return "PORT B4";
                case PORTB5:   return "PORT B5";
                case PORTB6:   return "PORT B6";
                case PORTB7:   return "PORT B7";
                case DAOUT0:   return "DA OUT 0";
                case DAOUT1:   return "DA OUT 1";
                case CH0_SE:   return "CH 0 IN";
                case CH1_SE:   return "CH 1 IN";
                case CH2_SE:   return "CH 2 IN";
                case CH3_SE:   return "CH 3 IN";
                case CH4_SE:   return "CH 4 IN";
                case CH5_SE:   return "CH 5 IN";
                case CH6_SE:   return "CH 6 IN";
                case CH7_SE:   return "CH 7 IN";
                case CH0_DIFF: return "CH 0 IN DIFF";
                case CH1_DIFF: return "CH 1 IN DIFF";
                case CH2_DIFF: return "CH 2 IN DIFF";
                case CH3_DIFF: return "CH 3 IN DIFF";
                default:       return "";
            }
        }

        /**
         * @return A channel or bit number of the connection
         */
        public uint8 to_uint8 () {
            switch (this) {
                case PORTA0:   return 0;
                case PORTA1:   return 1;
                case PORTA2:   return 2;
                case PORTA3:   return 3;
                case PORTA4:   return 4;
                case PORTA5:   return 5;
                case PORTA6:   return 6;
                case PORTA7:   return 7;
                case PORTB0:   return 0;
                case PORTB1:   return 1;
                case PORTB2:   return 2;
                case PORTB3:   return 3;
                case PORTB4:   return 4;
                case PORTB5:   return 5;
                case PORTB6:   return 6;
                case PORTB7:   return 7;
                case DAOUT0:   return 0;
                case DAOUT1:   return 1;
                case CH0_SE:   return 0;
                case CH1_SE:   return 1;
                case CH2_SE:   return 2;
                case CH3_SE:   return 3;
                case CH4_SE:   return 4;
                case CH5_SE:   return 5;
                case CH6_SE:   return 6;
                case CH7_SE:   return 7;
                case CH0_DIFF: return 0;
                case CH1_DIFF: return 1;
                case CH2_DIFF: return 2;
                case CH3_DIFF: return 3;
                default:       return 0x00;
            }
        }

    }

    /**
     * Analog input voltage measurement ranges
     */
    public enum Range {
        SE_10_00V,
        BP_20_00V,
        BP_10_00V,
        BP_5_00V,
        BP_4_00V,
        BP_2_50V,
        BP_2_00V,
        BP_1_25V,
        BP_1_00V;

        public static Range[] all () {
            return { SE_10_00V, BP_20_00V, BP_10_00V, BP_5_00V, BP_4_00V,
                    BP_2_50V, BP_2_00V, BP_1_25V, BP_1_00V };

        }

        public static Range parse (string value) {
            switch (value) {
                case "+ 10 V":   return SE_10_00V;
                case "± 20 V":   return BP_20_00V;
                case "± 10 V":   return BP_10_00V;
                case "± 5 V":    return BP_5_00V;
                case "± 4 V":    return BP_4_00V;
                case "± 2.5 V":  return BP_2_50V;
                case "± 2.0 V":  return BP_2_00V;
                case "± 1.25 V": return BP_1_25V;
                case "± 1.0 V":  return BP_1_00V;
                default:         return SE_10_00V;
            }
        }

        public string to_string () {
            switch (this) {
                case SE_10_00V: return "+ 10 V";
                case BP_20_00V: return "± 20 V";
                case BP_10_00V: return "± 10 V";
                case BP_5_00V:  return "± 5 V";
                case BP_4_00V:  return "± 4 V";
                case BP_2_50V:  return "± 2.5 V";
                case BP_2_00V:  return "± 2.0 V";
                case BP_1_25V:  return "± 1.25 V";
                case BP_1_00V:  return "± 1.0 V";
				default:        return "";
            }
        }

        /**
         * @return The range value that the the device uses
         */
        public uint8 to_mcc () {
            switch (this) {
                case SE_10_00V: return Mcc.Usb1208FS.SE_10_00V;
                case BP_20_00V: return Mcc.Usb1208FS.BP_20_00V;
                case BP_10_00V: return Mcc.Usb1208FS.BP_10_00V;
                case BP_5_00V:  return Mcc.Usb1208FS.BP_5_00V;
                case BP_4_00V:  return Mcc.Usb1208FS.BP_4_00V;
                case BP_2_50V:  return Mcc.Usb1208FS.BP_2_50V;
                case BP_2_00V:  return Mcc.Usb1208FS.BP_2_00V;
                case BP_1_25V:  return Mcc.Usb1208FS.BP_1_25V;
                case BP_1_00V:  return Mcc.Usb1208FS.BP_1_00V;
				default:        return Mcc.Usb1208FS.SE_10_00V;
            }
        }
    }

    private LibUSB.Context context;

    private LibUSB.DeviceHandle udev = null;

    private string serial_number;

    private Cld.RawChannel counter_channel;

    construct {
        id = "usb1208fs-ctl0";
        ao_channels = new Cld.AOChannel[2];
        //dio_channels = new Cld.DChannel[16];
        chrefs = new Gee.ConcurrentSet<string> ();
        btn_acquire.set_sensitive (false);
    }

    public Control.from_xml_node (Xml.Node *node) {
        build_from_xml_node (node);
/*
 *
 *        try {
 *            var provider = new Gtk.CssProvider ();
 *            var file = File.new_for_uri ("resource:///org/coanda/dactl/plugins/intelligent-pbw-3200/style.css");
 *            provider.load_from_file (file);
 *            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (),
 *                                                      provider,
 *                                                      600);
 *        } catch (GLib.Error e) {
 *            warning ("Error loading css style file: %s", e.message);
 *        }
 */

        /* Request the CLD data */
        request_data.begin ((obj, res) => {
            init ();
        });
    }

    /**
     * {@inheritDoc}
     */
    public override void build_from_xml_node (Xml.Node *node) {
        id = node->get_prop ("id");
        parent_ref = node->get_prop ("parent");
        debug ("Building `%s' with parent `%s'", id, parent_ref);

        for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {
            if (iter->name == "property") {
                switch (iter->get_prop ("name")) {
                    case "chref":
                        chrefs.add (iter->get_content ());
                        break;
                    case "sampling-rate":
                        sampling_rate = double.parse (iter->get_content ());
                        break;
                    case "acquisition-mode":
                        acquisition_mode = AcquisitionMode.parse (iter->get_content ());
                        break;
                    case "porta-direction":
                        var direction = iter->get_content ();
                        porta_direction = parse_direction (direction);
                        break;
                    case "portb-direction":
                        var direction = iter->get_content ();
                        portb_direction = parse_direction (direction);
                        break;
                    default:
                        break;
                }

                debug (" > Adding %s to %s", iter->get_content (), id);
            }
        }
    }

    /**
     * @return The direction as a value that is used by the device
     */
    private uint8 parse_direction (string direction) {
        uint8 dir8;
        switch (direction) {
            case "in":
                dir8 = Mcc.Usb1208FS.DIO_DIR_IN;
                break;
            case "out":
                dir8 = Mcc.Usb1208FS.DIO_DIR_OUT;
                break;
            default:
                dir8 = Mcc.Usb1208FS.DIO_DIR_IN;
                break;
        }

        return dir8;
    }

    /**
     * {@inheritDoc}
     *
     * FIXME: currently has no configurable property nodes or attributes
     */
    protected override void update_node () {
        for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {
            if (iter->name == "property") {
                switch (iter->get_prop ("name")) {
                    case "sampling-rate":
                        iter->set_content ("%.3f".printf (sampling_rate));
                        break;
                    case "acquisition-mode":
                        iter->set_content (acquisition_mode.to_string ());
                        break;
                    default:
                        break;
                }
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void offer_cld_object (Cld.Object object) {
        foreach (var chref in chrefs) {
            if (object.uri == chref) {
                var name = object.get_type().name();
                switch (name) {
                    case "CldAIChannel":
                        ai_channels+= object as Cld.AIChannel;
                        break;
                    case "CldAOChannel":
                        var num = (object as Cld.Channel).num;
                        ao_channels[num] = object as Cld.AOChannel;
                        break;
                    case "CldDIChannel":
                        dio_channels += object as Cld.DChannel;
                        break;
                    case "CldDOChannel":
                        dio_channels += object as Cld.DChannel;
                        break;
                    case "CldRawChannel":
                        counter_channel = object as Cld.RawChannel;
                        break;
                    default:
                        break;
                }
            }
        }

        chrefs.remove (object.uri);

        if (chrefs.size == 0)
            satisfied = true;
    }

    /**
     * {@inheritDoc}
     */
    protected async void request_data () {
        while (!satisfied) {
            foreach (var chref in chrefs) {
                request_object (chref);
            }
            // Try again in a second
            yield nap (1000);
        }
    }

    /**
     * Initialize the local data
     */
    private void init () {
        /* poulate range selector */
        var ranges = Range.all ();
        for (int i = 0; i < ranges.length; i++) {
            comboboxtext_range.append_text (ranges[i].to_string ());
        }
        comboboxtext_range.set_active (0);
        adjustment_rate.set_value (sampling_rate);

        /* connect analog output channels to corresponding Cld channel values */
        for (int i = 0; i < ao_channels.length; i++) {
            var chan = ao_channels[i];
            chan.new_value.connect ((id, value) => {
                if (btn_connect.active && btn_acquire.active) {
                    uint16 mcc_value = (uint16)(4095 * (value / 100));
                    Mcc.Usb1208FS.a_out (udev, (uint8)chan.num, mcc_value);
                }
            });
        }

		int ret = LibUSB.Context.init (out context);
		if (ret < 0) {
			warning ("LibUSB.init: Failed to initialize libusb");
			Posix.exit(1);
		}

		/* populate serial number selector */
		comboboxtext_serial_number.remove_all ();
        var list = get_serial_list ();
        for (int i = 0; i < list.length; i++) {
            comboboxtext_serial_number.append_text (list[i]);
        }
        comboboxtext_serial_number.set_active (0);

        var buttons = box_port_a.get_children ();
        foreach (var button in buttons) {
            (button as Gtk.Button).set_sensitive (true);
            (button as Gtk.ToggleButton).toggled.connect (() => {
                var context = button.get_style_context ();
                if ((button as Gtk.ToggleButton).get_active ())
                    context.add_class ("suggested-action");
                else
                    context.remove_class ("suggested-action");
            });
        }

        buttons = box_port_b.get_children ();
        foreach (var button in buttons) {
            (button as Gtk.Button).set_sensitive (true);
            (button as Gtk.ToggleButton).toggled.connect (() => {
                var context = button.get_style_context ();
                if ((button as Gtk.ToggleButton).get_active ())
                    context.add_class ("suggested-action");
                else
                    context.remove_class ("suggested-action");
            });
        }
    }

    /**
     * @return a list of connected USB-1208FS serial numbers
     */
    private string[] get_serial_list () {
        // declare objects
        LibUSB.Device[] devices;
        LibUSB.Device device;
        LibUSB.DeviceDescriptor desc;
        LibUSB.DeviceHandle devhandle;
        uchar[] serial_number = new uchar[9];
        int i = 0;
        string[] result = null;

        // initialize LibUSB and get the device list
        context.get_device_list (out devices);

        debug ("\n USB Device List\n---------------\n");
        // iterate through the list
        while (devices[i] != null)
        {
            device = devices[i];
            desc = DeviceDescriptor (device);
            if ((desc.idVendor == Mcc.Pmd.MCC_VID) &&
                 desc.idProduct == Mcc.Usb1208FS.PID) {
                device.open (out devhandle);
                if (desc.iSerialNumber > 0) {
                    devhandle.get_string_descriptor_ascii (
                                             desc.iSerialNumber, serial_number);
                    /*stdout.printf ("\n Serial Number : %s\n", (string)serial_number);*/
                    result+= (string)serial_number;
                }
            }
            i++;
        }
        //stdout.printf ("\n");

        return result;
    }

    private uchar[] test_udev () {
        LibUSB.Device[] devices;
        LibUSB.Device device;
        LibUSB.DeviceDescriptor desc;
        uchar[] result = new uchar[9];

        device = udev.get_device ();
        desc = DeviceDescriptor (device);
        udev.get_string_descriptor_ascii (desc.iSerialNumber, result);
        debug ("Serial Number : %s", (string)result);

        return result;
    }

    private bool is_connected () {
        LibUSB.DeviceHandle handle;
        LibUSB.Device device = udev.get_device ();
        bool result;

        if (device.open (out handle) == LibUSB.Error.NO_DEVICE) {
            result = false;
            debug ("btn con set act false");
            btn_acquire.set_active (false);
            btn_connect.set_active (false);
        } else {
            result = true;
        }

        return result;
    }

    [GtkCallback]
    private void comboboxtext_serial_number_changed_cb () {
        var value = comboboxtext_serial_number.get_active_text ();
        debug ("Serial number changed to %s", value);
    }

    [GtkCallback]
    private void comboboxtext_input_changed_cb () {
        var value = comboboxtext_input.get_active_text ();
        debug ("Input channel changed to %s", value);
    }

    [GtkCallback]
    private void comboboxtext_range_changed_cb () {
        var chan = comboboxtext_input.get_active ();
        var val = Range.parse (comboboxtext_range.get_active_text ());
        var value = comboboxtext_range.get_active_text ();
        var array = Connection.diff_inputs ();

        debug ("Input channel range changed to %s", value);

        /* populate ai channel selector */
        if (val == Range.SE_10_00V) {
            array = Connection.se_inputs ();
        }
		    comboboxtext_input.remove_all ();
        for (int i = 0; i < array.length; i++)
            comboboxtext_input.append_text (array[i].to_string ());
        comboboxtext_input.set_active (0);
        if ((chan <= array.length) && (chan > 0)) {
            comboboxtext_input.set_active (chan);
        }
    }

    [GtkCallback]
    private void btn_connect_toggled_cb () {
        debug ("connect toggled");
        if (btn_connect.active) {
            if (mcc_connect ()) {
                btn_connect.set_label ("Disconnect");
                btn_connect.set_image (img_disconnect);
                btn_acquire.set_sensitive (true);
                btn_blink.set_sensitive (false);
                expander_settings.set_sensitive (true);
                expander_test.set_sensitive (true);
                adjustment_output0.set_value (0);
                adjustment_output1.set_value (0);
                sample_test_mode.begin ((obj, res) => {
                    debug ("Test mode ended");
                });
            } else {
                warning ("Unable to connect!");
                btn_connect.set_active (false);
                expander_settings.set_sensitive (false);
                expander_test.set_sensitive (false);
            }
        } else if (!btn_acquire.active) {
            btn_connect.set_label ("Connect");
            btn_connect.set_image (img_connect);
            udev = null;
            btn_acquire.set_sensitive (false);
            btn_blink.set_sensitive (true);
            expander_test.set_sensitive (false);
            expander_settings.set_sensitive (false);
        } else {

        }
    }

    /**
     * @return true if a device was found
     */
    private bool mcc_connect () {
        /* XXX Serial number selection is not working */
        var selected = comboboxtext_serial_number.get_active_text ();
        var data = selected.data;
        data+= '\0';
        if (data.length == 9)
            udev = Mcc.Pmd.usb_device_find_usb_mcc(Mcc.Usb1208FS.PID, data);
        if (udev == null) {
            warning ("No device found.\n");

            return false;
        } else {
            debug ("USB-1208FS Devices is found: %s %s\n", (string)test_udev (), selected);
            Mcc.Usb1208FS.init (udev);

            return true;
        }
    }

    /**
     * Data sampling and channel value updates
     */
    private async void acquire () throws GLib.ThreadError {
        GLib.SourceFunc callback = acquire.callback;
        int64 start_time_mono = get_monotonic_time ();
        int count = 0;

        Mcc.Usb1208FS.config_port (udev,
                                      Mcc.Usb1208FS.DIO_PORTA, porta_direction);
        Mcc.Usb1208FS.config_port (udev,
                                      Mcc.Usb1208FS.DIO_PORTB, portb_direction);

        GLib.Thread<int> thread = new GLib.Thread<int>.try ("acquire",  () => {
            Mutex mutex = new Mutex ();
            Cond cond = new Cond ();
            int64 end_time = start_time_mono;

            while (btn_acquire.get_active () && is_connected ()) {
                /* update the the channel values */
                update ();

                mutex.lock ();
                try {
                    end_time = start_time_mono + count++ * (int)(1000 /
                               sampling_rate) * TimeSpan.MILLISECOND;
                    while (cond.wait_until (mutex, end_time))
                        ; /* do nothing */
                } finally {
                    mutex.unlock ();
                }
            }

            Idle.add ((owned) callback);

            return 0;
        });

        yield;
    }

    private void update () {
        update_analog ();
        update_digital (Mcc.Usb1208FS.DIO_PORTA);
        update_digital (Mcc.Usb1208FS.DIO_PORTB);
        update_counter ();
    }

    private void update_analog () {
        for (int i = 0; i < ai_channels.length; i++) {
            var gain = ((Range)ai_channels[i].range).to_mcc ();
            uint8 channel = (uint8)ai_channels[i].num;
            short svalue = Mcc.Usb1208FS.a_in (udev, channel, gain);
            /*
             *stdout.printf("Channel: %d: gain: %u value = %#hx, %.2fV\n",
             *                                   channel, gain,  svalue,
             *                                   Mcc.Usb1208FS.volts_se (svalue));
             */
            if (gain == Mcc.Usb1208FS.SE_10_00V)
                ai_channels[i].add_raw_value (Mcc.Usb1208FS.volts_se (svalue));
            else
                ai_channels[i].add_raw_value (Mcc.Usb1208FS.volts_fs (gain, svalue));
        }

        ao_channels[0].new_value (ao_channels[0].id, ao_channels[0].scaled_value);
        var value = (uint16)(ao_channels[0].scaled_value * 4090 / 100);
		Mcc.Usb1208FS.a_out (udev, 0, value);

        ao_channels[1].new_value (ao_channels[1].id, ao_channels[1].scaled_value);
        value = (uint16)(ao_channels[1].scaled_value * 4090 / 100);
		Mcc.Usb1208FS.a_out (udev, 1, value);
    }

    private void update_digital (uint8 port) {
        uint8 bit = 0x01;
        uint8 value = 0x00;
        Connection connection;
        Gee.List<Connection> port_connections;
        uint8 direction;

        switch (port) {
            case Mcc.Usb1208FS.DIO_PORTA:
                direction = porta_direction;
                port_connections = Connection.porta ();
                break;
            case Mcc.Usb1208FS.DIO_PORTB:
                direction = portb_direction;
                port_connections = Connection.portb ();
                break;
            default:
                return;
        }

        if (direction == Mcc.Usb1208FS.DIO_DIR_OUT) {
            /* Output */
            for (int i = 0;  i < dio_channels.length; i++) {
                var channel = dio_channels[i];
                connection = (Connection)channel.num;
                if ((channel is Cld.DOChannel) &&
                                     (port_connections.contains (connection))) {
                    if (channel.state) {
                        value |= bit<<(connection.to_uint8 ());
                        debug ("%2X %2X %d", value,  bit<<(connection.to_uint8 ()), connection);
                    }
                }
            }
            debug ("value: %2X", value);
            Mcc.Usb1208FS.d_out (udev, port, value);

        } else if (direction == Mcc.Usb1208FS.DIO_DIR_IN) {
            /* Input */
            value = 0x00;
            uint8* ptr = &value;

            Mcc.Usb1208FS.d_in (udev, port, ptr);
            debug ("PORTA in: %2X", value);
            for (int i = 0;  i < dio_channels.length; i++) {
                var channel = dio_channels[i];
                if (channel is Cld.DIChannel) {
                    connection = (Connection)channel.num;
                    if (port_connections.contains (connection)) {
                        var mask = bit<<(connection.to_uint8 ());
                        if ((value & mask) == mask)
                            (channel as Cld.DChannel).state = true;
                        else
                            (channel as Cld.DChannel).state = false;
                    }
                }
            }
        }
    }

    private void update_counter () {
        /* Read the counter */
        counter_value = Mcc.Usb1208FS.read_counter (udev);
        counter_channel.value = (uint16)counter_value;
    }

    [GtkCallback]
    private void btn_acquire_toggled_cb () {
        debug ("acquire toggled");
        if (btn_acquire.active) {
            btn_acquire.set_label ("Stop");
            btn_acquire.set_image (img_stop);
            btn_connect.set_sensitive (false);
            expander_test.set_sensitive (false);
            expander_settings.set_sensitive (false);
            acquire.begin ((obj, res) => {
                debug ("Acquisition ended");
                btn_acquire.set_active (false);
            });
        } else {
            btn_acquire.set_label ("Acquire");
            btn_acquire.set_image (img_acquire);
            btn_connect.set_sensitive (true);
            expander_test.set_sensitive (true);
            expander_settings.set_sensitive (true);
            adjustment_output0.set_value (ao_channels[0].scaled_value * 40.95);
            adjustment_output1.set_value (ao_channels[1].scaled_value * 40.95);
            sample_test_mode.begin ((obj, res) => {
                debug ("Test mode ended");
            });
        }
    }

    [GtkCallback]
    private void btn_blink_clicked_cb () {
        udev = null;
        if (mcc_connect ()) {
            Mcc.Usb1208FS.blink (udev);
            debug ("%s Button blink clicked", (string)test_udev ());
        }
        udev = null;
    }

    [GtkCallback]
    private void adjustment_output0_value_changed_cb () {
        var value = (uint16)adjustment_output0.get_value ();
        debug ("Output value changed: %.3f", value);
		Mcc.Usb1208FS.a_out (udev, 0, value);
    }

    [GtkCallback]
    private void adjustment_output1_value_changed_cb () {
        var value = (uint16)adjustment_output1.get_value ();
        debug ("Output value changed: %.3f", value);
		Mcc.Usb1208FS.a_out (udev, 1, value);
    }

    [GtkCallback]
    private void adjustment_rate_value_changed_cb () {
        var value = (uint16)adjustment_rate.get_value ();
        debug ("Sampling Rate value changed: %.3f", value);
        sampling_rate = value;
    }

    /**
     * Test mode sampling (no channel value updates)
     */
    private async void sample_test_mode () {
        Mcc.Usb1208FS.init_counter (udev);

        while (btn_connect.get_active () &&
               !btn_acquire.get_active () &&
               is_connected ()) {

            var gain = ((Range)comboboxtext_range.get_active ()).to_mcc ();
            uint8 channel = (uint8)comboboxtext_input.get_active ();
            short svalue = Mcc.Usb1208FS.a_in (udev, channel, gain);
            debug ("Channel: %d: value = %#hx, %.2fV\n",
                                               channel, svalue,
                                               Mcc.Usb1208FS.volts_se (svalue));
            double val;
            if (gain == Mcc.Usb1208FS.SE_10_00V) {
                val = Mcc.Usb1208FS.volts_se (svalue);
            } else {
                val = Mcc.Usb1208FS.volts_fs (gain, svalue);
            }

            entry_input_value.set_text ("%6.3f".printf(val));

            /* Update DIO Ports */
            uint8 bit = 0x01;
            var buttons = box_port_a.get_children ();

            if (!radiobutton_port_a_in.active) {
                /* Set PORTA ouputs */
                uint8 value = 0x00;
                uint8 count = 0x07;

                foreach (var button in buttons) {
                    if ((button as Gtk.ToggleButton).active) {
                        value |= bit<<count;
                    }
                    count--;
                }

                debug ("value: %2X", value);
                Mcc.Usb1208FS.d_out (udev, Mcc.Usb1208FS.DIO_PORTA, value);
            } else {
                /* Read PORTA inputs */
                uint8 din_value = 0x00;
                uint8* ptr = &din_value;
                uint8 count = 0x07;

                Mcc.Usb1208FS.d_in (udev, Mcc.Usb1208FS.DIO_PORTA, ptr);
                debug ("PORTA in: %2X", din_value);
                foreach (var button in buttons) {
                    var mask = bit<<count;
                    if ((din_value & mask) == mask)
                        (button as Gtk.ToggleButton).set_active (true);
                    else
                        (button as Gtk.ToggleButton).set_active (false);

                    count--;
                }
            }

            buttons = box_port_b.get_children ();
            if (!radiobutton_port_b_in.active) {
                /* Set PORTB outputs */
                uint8 value = 0x00;
                uint8 count = 0x07;

                foreach (var button in buttons) {
                    if ((button as Gtk.ToggleButton).active) {
                        value |= bit<<count;
                    }
                    count--;
                }

                debug ("value: %2X", value);
                Mcc.Usb1208FS.d_out (udev, Mcc.Usb1208FS.DIO_PORTB, value);
            } else {
                /* Read PORTB inputs */
                uint8 din_value = 0x00;
                uint8* ptr = &din_value;
                uint8 count = 0x07;

                Mcc.Usb1208FS.d_in (udev, Mcc.Usb1208FS.DIO_PORTB, ptr);
                debug ("PORTB in: %2X buttons: %u", din_value, buttons.length ());
                foreach (var button in buttons) {
                    var mask = bit<<count;
                    if ((din_value & mask) == mask)
                        (button as Gtk.ToggleButton).set_active (true);
                    else
                        (button as Gtk.ToggleButton).set_active (false);

                    count--;
                }
            }

            /* Read the counter */
            counter_value = Mcc.Usb1208FS.read_counter (udev);
            entry_counter.set_text ("%010u".printf (counter_value - counter_offset));

            yield nap (100);
        }
    }

    [GtkCallback]
    private void radiobutton_port_a_in_toggled_cb () {
        uint8 direction = Mcc.Usb1208FS.DIO_DIR_OUT;
        bool is_sensitive = true;
        if (radiobutton_port_a_in.active) {
            direction = Mcc.Usb1208FS.DIO_DIR_IN;
            is_sensitive = false;
        }

        Mcc.Usb1208FS.config_port (udev, Mcc.Usb1208FS.DIO_PORTA, direction);
        var list = box_port_a.get_children ();
        foreach (var button in list) {
            debug ("PORTA%s", (button as Gtk.Button).get_label ());
            (button as Gtk.Button).set_sensitive (is_sensitive);
        }
    }

    [GtkCallback]
    private void radiobutton_port_b_in_toggled_cb () {
        uint8 direction = Mcc.Usb1208FS.DIO_DIR_OUT;
        bool is_sensitive = true;
        if (radiobutton_port_b_in.active) {
            direction = Mcc.Usb1208FS.DIO_DIR_IN;
            is_sensitive = false;
        }

        Mcc.Usb1208FS.config_port (udev, Mcc.Usb1208FS.DIO_PORTB, direction);
        var list = box_port_b.get_children ();
        foreach (var button in list) {
            debug ("PORTB%s", (button as Gtk.Button).get_label ());
            (button as Gtk.Button).set_sensitive (is_sensitive);
        }
    }

    [GtkCallback]
    private void btn_reset_counter_clicked_cb () {
        counter_offset = counter_value;
    }
}
