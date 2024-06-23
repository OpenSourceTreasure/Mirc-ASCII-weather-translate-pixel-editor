This is a collection of a few irc scripts and a bot that work together.
Install the bot based on the below instructions.
Place the scripts files in the correct directory
Load your irc server - I used unrealircd.
Load Mirc. 
Go to the dir where the bot is and open Terminal. Type: node index.js
In C:\Users\name\AppData\Roaming\mIRC\scripts\irc-translate-bot-main - change Boca Raton to whatever city you'd like.
The channels default to #Ken - you may change that in the channels.js files

Usage:

!weather - for the weather

/pe - pixel editor

-es words (Google Translate - change es for any two letter language code and "words" for what you want to translate!)

Go to Commands in Mirc for Mario and Pixel Editor

Where a directory refers to "kenny" instead of "name" - same idea, change it to whatever it is on your end...

This is what it should look like when you use it:

![screenshot](mirc-bot.png)

# irc-translate-bot
An irc translation bot using Google Translate, works for every language.
It it located here - https://github.com/forerosantiago/irc-translate-bot

## Installation

First, clone this repository and cd into it:
```
git clone https://github.com/forerosantiago/irc-translate-bot && cd irc-translate-bot/
```

Install the dependencies:
```
npm install
```

Edit the `config.json` file:
```
{
    "nick": "Translator",
    "server": "irc.planetofnix.com"
}
```

Execute it:
```
node index.js
```

## Usage
Once the bot is running and connected to an irc server you can use it like this:

```
-es Text to be translated
```

The command is the iso code for the desired language, a list of all the iso language codes can be found [here](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes).


### Joining and leaving channels
You can make the bot join any channel you want using the irc `/invite` commmand, the bot will remember it and join again if it gets disconnected.

If you don't want the bot to be in your channel anymore you can simply use the `/kick` command with it, it will forget your channel and won't come back unless reinvited.

