# discord-css-injection
A bash script that uses 'asar', 'grep', and 'sed' to add CSS hotloading to Discord Canary.  This script more than likely only works on Linux.

The function for hotloading CSS and the 'cssInjection.js' script are both from [BeautifulDiscord](https://github.com/leovoel/BeautifulDiscord).

To use `discord-css-injection.sh`, you can grab the AppImage from the [releases page](https://github.com/simoniz0r/discord-css-injection/releases).  The AppImage works the same as the script, but it contains `nodejs` and `asar`.  To use the AppImage release, do the following:

```
chmod +x /path/to/discord-css-injection-VERSION-x86_64.AppImage
/path/to/discord-css-injection-VERSION-x86_64.AppImage --help
```

If you already have `nodejs` and `asar`, you can just grab the script and make it executable by doing the following:

```
git clone https://github.com/simoniz0r/discord-css-injection.git
cd ./discord-css-injection.git
chmod +x ./discord-css-injection.git
```

Optionally, you can specify the directory of your custom CSS file by adding it as an argument.  For example:

```
/path/to/discord-css-injection.sh /home/simonizor/Documents/custom-css.css
```

Changes may be reverted by using the `--revert` argument.
