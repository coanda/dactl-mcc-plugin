public void module_init (Dactl.PluginLoader loader) {
    try {
        // Instantiate the plugin object
        var plugin = new Dactl.usb1208fs.Plugin ();
        plugin.active = true;

        loader.add_plugin (plugin);
    } catch (Error error) {
        warning ("Failed to load %s: %s",
                 Dactl.usb1208fs.Plugin.NAME,
                 error.message);
    }
}

public class Dactl.usb1208fs.Plugin : Dactl.Plugin {

    public const string NAME = "usb1208fs";

    private bool _has_factory = true;
    public override bool has_factory { get { return _has_factory; } }

    /**
     * Instantiate the plugin.
     */
    public Plugin () {
        // Call the base constructor,
        base (NAME, null, null, Dactl.PluginCapabilities.CLD_OBJECT);
        factory = new Dactl.usb1208fs.Factory ();
    }
}
