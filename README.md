# discord-css-injection
A bash script that uses 'asar', 'grep', and 'sed' to add CSS hotloading to Discord Canary.  This script more than likely only works on Linux.

The function for hotloading CSS and the 'cssInjection.js' script are both from [BeautifulDiscord](https://github.com/leovoel/BeautifulDiscord).

To use `discord-css-injection.sh`, just grab the script from this repo, make it executable, and run it.  Optionally, you can specify the directory of your custom CSS file by adding it as an argument.  For example:

```
/path/to/discord-css-injection.sh /home/simonizor/Documents/custom-css.css
```
