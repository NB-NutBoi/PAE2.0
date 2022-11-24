package leveleditor;

import lime.app.Application;
import lime.utils.Assets;

class LevelEditor extends CoreState {
    public static var instance:LevelEditor;

    override function create() {
        super.create();

        instance = this;

        //map-icon
        Application.current.window.setIcon(Assets.getImage("embed/defaults/leveleditor/icon512.png"));

        Application.current.window.title = "PAE2.0 - Level editor - Unnamed map.";
    }

    @:access(Main)
    override function destroy() {

        //reset to default
        instance = null;

        Application.current.window.setIcon(Main._getWindowIcon(Main.SetupConfig.getConfig("WindowIcon", "string", "embed/defaults/icon32.png")));
		Application.current.window.title = Main.SetupConfig.getConfig("WindowName", "string", "PAE 2.0");

        super.destroy();
    }
}