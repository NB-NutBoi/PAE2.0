# HOW TO BUILD THE ENGINE

You're going to need [Haxe 4.2.5](https://haxe.org/download/version/4.2.5/) as it is the version the engine was last compiled in.<br />
Newer versions might work, but are untested as of November 21st 2022.

To build the engine, you should be familiar with the commandline. If not, read this [quick guide by ninjamuffin](https://ninjamuffin99.newgrounds.com/news/post/1090480).

**Also note**: To build for *Windows*, you need to be on *Windows*. To build for *Linux*, you need to be on *Linux*. Same goes for macOS.

## DEPENDENCIES

1. Install git.
   - **FOR WINDOWS**: install from the [git-scm](https://git-scm.com/downloads) website.
   - **FOR LINUX**: install the `git` package: `sudo apt install git` (ubuntu), `sudo pacman -S git` (arch), etc... (you probably already have it)
2. Install and set up the necessary libraries:
   - `haxelib install hxcpp`
   - `haxelib install lime`
   - `haxelib install openfl`
   - `haxelib install flixel`
   - `haxelib install flixel-addons`
   - `haxelib install hscript`
   - `haxelib install dconsole`
   - `haxelib run lime setup`
   - `haxelib run lime setup flixel`
   - `haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc` (Windows only)

---------------------------------------
### Windows only dependencies
If you are building for Windows, you will also need to install **Visual Studio 2019**. While installing it, *don't click on any of the options to install workloads*. Instead, go to the **individual components** tab and choose the following:

-   MSVC v142 - VS 2019 C++ x64/x86 build tools
-   Windows SDK (10.0.17763.0)

This will install around 4 GB of stuff, but it is necessary to build for Windows.

---------------------------------------
### macOS only dependencies
TODO MAKE MAC BUILD AND DOCUMENT.

## Building
Once everything is installed and set up, we can build.

- Run `lime build <target>`, replacing `<target>` with the platform you want to build to (`windows`, `mac`, `linux`) (i.e. `lime build windows`)
- The build will be in `PAE2.0/export/release/<target>/bin`, with `<target>` being the target you built to in the previous step. (i.e. `PAE2.0/export/windows/bin`)
- Only the `bin` folder is necessary to run the game. The other ones in `export/release/<target>` are not.
