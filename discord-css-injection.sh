#!/bin/bash -e
# Title: discord-css-injection
# Description: Uses asar, grep, and sed to add the cssInjection.js script from BeautifulDiscord into Discord Canary's config dir
# Description: Currently only works with Discord Canary, but support for other versions will be added when `core.asar` is pushed to them
# License: MIT
# Dependencies: nodejs, asar

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")"
# Detect the directory containing the modules directory using grep
VERSION_DIR="$(dir -C -w 1 "$HOME"/.config/discordcanary | grep '^[0-9].')"
# Set the path to the CSS file that the user will put their CSS changes in
if [ -z "$1" ]; then
    CSS_PATH="$HOME/.config/discordcanary/custom-css.css"
else
    case $1 in
        --revert)
            if [ ! -f "$HOME/.config/discordcanary/$VERSION_DIR/modules/discord_desktop_core/core.asar.bak" ]; then
                echo "'core.asar.bak' not found!"
                echo "Has '$HOME/.config/discordcanary' been modified?"
                exit 1
            fi
            echo "Removing previously modified 'core.asar' and restoring 'core.asar.bak'..."
            rm -rf "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/app
            rm -rf "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/common
            rm -rf "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/node_modules
            mv "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar.bak "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar
            echo "Reverted changes to '$HOME/.config/discordcanary/$VERSION_DIR/modules/discord_desktop_core/'"
            echo "If Discord Canary is running, please restart it for CSS hotloading to be removed."
            exit 0
            ;;
        --help)
            echo "discord-css-injection.sh - Add CSS hotloading to Discord Canary"
            echo "Usage: /path/to/discord-css-injection.sh [option]"
            echo
            echo "The path for your custom CSS file may be specified.  For example:"
            echo "'/path/to/discord-css-injection.sh $HOME/Documents/custom-css.css'"
            echo
            echo "Arguments:"
            echo "  --revert - Revert changes to Discord Canary and remove CSS hotloading"
            echo "  --help   - Show this help output"
            exit 0
            ;;
        *)
            if [ ! -d "$(dirname $1)" ]; then
                echo "'$1' is not a valid directory or does not exist!"
                exit 1
            fi
            CSS_PATH="$(readlink -f "$1")"
            ;;
    esac
fi
if [ ! -f "$HOME/.config/discordcanary/$VERSION_DIR/modules/discord_desktop_core/core.asar" ]; then
    echo "core.asar not found!"
    echo "Has '$HOME/.config/discordcanary' already been modified by another app?"
    exit 1
fi

# Remove extracted directories and backed up core.asar.bak if they exist
if [ -f "$HOME/.config/discordcanary/$VERSION_DIR/modules/discord_desktop_core/core.asar.bak" ]; then
    read -p "Previous backup found; remove and continue? Y/N " REMOVE_ANSWER
    case $REMOVE_ANSWER in
        Y|y)
            echo "Removing previous core.asar.bak file..."
            rm -rf "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/app
            rm -rf "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/common
            rm -rf "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/node_modules
            rm -f "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar.bak
            ;;
        *)
            echo "Previous backup was not removed and no modifications were made!"
            exit 0
            ;;
    esac
fi

# Clean up on failure
function injectionfailure() {
    rm -rf /tmp/discord-css-injection
    if [ -f "$HOME/.config/discordcanary/$VERSION_DIR/modules/discord_desktop_core/core.asar.bak" ]; then
        mv "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar.bak "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar
    fi
    exit 1
}

# Use 'asar' to extract 'core.asar' to '/tmp/discord-css-injection'
echo "Using 'asar' to extract 'core.asar'..."
if [ ! -d "/tmp/discord-css-injection" ]; then
    mkdir /tmp/discord-css-injection
else
    rm -rf /tmp/discord-css-injection
    mkdir /tmp/discord-css-injection
fi
if [ -f "$HOME/node_modules/.bin/asar" ]; then
    ~/node_modules/.bin/asar e "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar /tmp/discord-css-injection/ || { echo "Failed to extract 'core.asar'!"; injectionfailure; }
elif [ -f "$RUNNING_DIR/../share/discord-css-injection/node_modules/asar/bin/asar.js" ]; then
    "$RUNNING_DIR"/../share/discord-css-injection/node_modules/asar/bin/asar.js e "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar /tmp/discord-css-injection/ || { echo "Failed to extract 'core.asar'!"; injectionfailure; }
elif type asar >/dev/null 2>&1; then
    asar e "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar /tmp/discord-css-injection/ || { echo "Failed to extract 'core.asar'!"; injectionfailure; }
else
    echo "'asar' not found; could not extract 'core.asar'!"
    injectionfailure
fi

# Create a backup of 'core.asar' just in case
echo "Moving 'core.asar' to 'core.asar.bak'..."
mv "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar.bak

# Use sed to add variables fs and fs2 to mainScreen.js right above the path varaible
echo "Adding necessary variables and function for hotloading CSS to '/tmp/discord-css-injection/app/mainScreen.js'..."
sed -i '/var _path = require.*;/ i \
var _fs = require('"'"'fs'"'"');\
\
var _fs2 = _interopRequireDefault(_fs);\
' /tmp/discord-css-injection/app/mainScreen.js || { echo "Failed to modify 'mainScreen.js'!"; injectionfailure; }

# Use sed to add the function from BeautifulDiscord to hotload CSS to mainScreen.js directly above the crash detection function
sed -i '/  mainWindow.webContents.on(*..*, function (e, killed).*/ i \
  mainWindow.webContents.on('"'"'dom-ready'"'"', function () {\
    mainWindow.webContents.executeJavaScript(\
      _fs2.default.readFileSync('"'"'/home/simonizor/.config/discordcanary/cssInjection.js'"'"', '"'"'utf-8'"'"')\
    );\
  });\
' /tmp/discord-css-injection/app/mainScreen.js || { echo "Failed to modify 'mainScreen.js'!"; injectionfailure; }
# Replace the cssInjection.js path with the proper path using $HOME
sed -i "s%/home/simonizor/.config/discordcanary/cssInjection.js%$HOME/.config/discordcanary/cssInjection.js%g" /tmp/discord-css-injection/app/mainScreen.js
# Use 'asar' to pack '/tmp/discord-css-injection' to '$HOME/.config/discordcanar/$VERSION_DIR/modules/discord_desktop_core/core.asar'
echo "Packing '/tmp/discord-css-injection' to '$HOME/.config/discordcanar/$VERSION_DIR/modules/discord_desktop_core/core.asar'..."
if [ -f "$HOME/node_modules/.bin/asar" ]; then
    ~/node_modules/.bin/asar p /tmp/discord-css-injection/ "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar || { echo "Failed to pack 'core.asar'!"; injectionfailure; }
elif [ -f "$RUNNING_DIR/../share/discord-css-injection/node_modules/asar/bin/asar.js" ]; then
    "$RUNNING_DIR"/../share/discord-css-injection/node_modules/asar/bin/asar.js p /tmp/discord-css-injection/ "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar || { echo "Failed to pack 'core.asar'!"; injectionfailure; }
elif type asar >/dev/null 2>&1; then
    asar p /tmp/discord-css-injection/ "$HOME"/.config/discordcanary/"$VERSION_DIR"/modules/discord_desktop_core/core.asar || { echo "Failed to pack 'core.asar'!"; injectionfailure; }
else
    rm -rf /tmp/discord-css-injection
    echo "'asar' not found; could not pack 'core.asar'!"
    injectionfailure
fi
rm -rf /tmp/discord-css-injection
# Create cssInjection.js from BeautifulDiscord in $HOME/.config/discordcanary
if [ -f "$HOME/.config/discordcanary/cssInjection.js" ]; then
    rm "$HOME"/.config/discordcanary/cssInjection.js
fi
echo "Creating '$HOME/.config/discordcanary/cssInjecton.js' for hotloading CSS..."
cat >"$HOME"/.config/discordcanary/cssInjection.js << EOL
window._fs = require("fs");
window._path = require("path");
window._fileWatcher = null;
window._styleTag = {};

window.applyCSS = function(path, name) {
  var customCSS = window._fs.readFileSync(path, "utf-8");
  if (!window._styleTag.hasOwnProperty(name)) {
    window._styleTag[name] = document.createElement("style");
    document.head.appendChild(window._styleTag[name]);
  }
  window._styleTag[name].innerHTML = customCSS;
}

window.clearCSS = function(name) {
  if (window._styleTag.hasOwnProperty(name)) {
    window._styleTag[name].innerHTML = "";
    window._styleTag[name].parentElement.removeChild(window._styleTag[name]);
    delete window._styleTag[name];
  }
}

window.watchCSS = function(path) {
  if (window._fs.lstatSync(path).isDirectory()) {
    files = window._fs.readdirSync(path);
    dirname = path;
  } else {
    files = [window._path.basename(path)];
    dirname = window._path.dirname(path);
  }

  for (var i = 0; i < files.length; i++) {
    var file = files[i];
    if (file.endsWith(".css")) {
      window.applyCSS(window._path.join(dirname, file), file)
    }
  }

  if(window._fileWatcher === null) {
    window._fileWatcher = window._fs.watch(path, { encoding: "utf-8" },
      function(eventType, filename) {
        if (!filename.endsWith(".css")) return;
        path = window._path.join(dirname, filename);
        if (eventType === "rename" && !window._fs.existsSync(path)) {
          window.clearCSS(filename);
        } else {
          window.applyCSS(window._path.join(dirname, filename), filename);
        }
      }
    );
  }
};

window.tearDownCSS = function() {
  for (var key in window._styleTag) {
    if (window._styleTag.hasOwnProperty(key)) {
      window.clearCSS(key)
    }
  }
  if(window._fileWatcher !== null) { window._fileWatcher.close(); window._fileWatcher = null; }
};

window.applyAndWatchCSS = function(path) {
  window.tearDownCSS();
  window.watchCSS(path);
};

window.applyAndWatchCSS('/home/simonizor/github/DiscordThemes/compact-discord/compact-discord.css');

EOL
# Use sed to change the path for the custom CSS file to the path inputted by the user or the default path if no input
sed -i "s%/home/simonizor/github/DiscordThemes/compact-discord/compact-discord.css%$CSS_PATH%g" "$HOME"/.config/discordcanary/cssInjection.js
# Create the custom CSS file if it does not exist to avoid errors
if [ ! -f "$CSS_PATH" ]; then
    touch "$CSS_PATH"
fi
echo "Finished injecting variables and function for hotloading CSS into Discord Canary!"
echo "You may edit your custom CSS file in $CSS_PATH"
echo "Discord Canary must be restarted before CSS hotloading will work; please do so now."
exit 0
