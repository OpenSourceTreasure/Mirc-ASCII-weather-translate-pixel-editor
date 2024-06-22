const fs = require('fs');
const translate = require('@iamtraction/google-translate');
const https = require('https');
const cheerio = require('cheerio');

const config = JSON.parse(fs.readFileSync('config.json'));
const channels = require('./channels.json').channels;

const irc = require('irc');
const client = new irc.Client(config.server, config.nick, {
  channels
});

console.log(config.server, config.nick);

client.on('message', (nick, to, text) => {
  const lowercase = text.toLowerCase();
  if (lowercase === '-help' || lowercase === `${config.nick.toLowerCase()} help` || lowercase === config.nick.toLowerCase()) {
    client.say(to, `${nick}: Hello, I'm a translation bot developed by forero, translate to your desired language using the ISO 639-1 code or ISO 639-3 code like this: -es Text to be translated. Note: if the iso code is invalid I will not respond.`);
    client.say(to, 'I can join any channel you want! just invite me using the the /invite command and I\'ll join immediately :) if you want me to stop joining your channel just kick me and I won\'t come back. My source code is available at https://github.com/forerosantiago/irc-translate-bot');
  } else if (lowercase.startsWith('!say ')) {
    const messageToSend = text.slice(5); // Extract the message to send
    client.say(to, messageToSend); // Make the bot say the message
  } else if (lowercase.startsWith('-')) {
    const iso = lowercase.slice(1).trim().split(/ +/)[0];
    const textToTranslate = text.slice(iso.length + 2).trim(); // Correctly extract the text to be translated
    translate(textToTranslate, { to: iso }).then(res => {
      const translatedText = res.text;
      client.say(to, translatedText.trim());
      console.log(res);
    }).catch(err => {
      console.error(err);
    });
  } else if (lowercase.startsWith('!weather')) {
    // Fetch weather information from wttr.in
    https.get('https://wttr.in/Boca+Raton', (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        // Parse HTML using cheerio
        const $ = cheerio.load(data);
        // Extract text content from the HTML
        const weatherText = $('pre').text().trim();
        // Send only the top part of the weather information to the channel with blank lines before and after
        const lines = weatherText.split('\n');
        const topWeatherInfo = `${lines.slice(1, 7).join('\n')}\n`; // Add space for blank lines
        client.say(to, topWeatherInfo);
      });
    }).on('error', (err) => {
      console.error('Error fetching weather:', err.message);
    });
  }
});
