const Discord = require('discord.js')
const AWS = require('aws-sdk')
const ssm = new AWS.SSM({ region: 'ca-central-1' })
const client = new Discord.Client()

ssm.getParameter({ Name: 'scallywag-bot-secret', WithDecryption: true}).promise()
    .then(data => data.Parameter.Value)
    .then(token => {
        client.on('ready', () => {
            console.log('Scallywag Bot is ready to handle requests...')
        })

        client.on('message', message => {
            if (message.member.hasPermission('ADMINISTRATOR') && message.content === "!start") {
                console.log(`${new Date().toISOString()}: received start request from ${message.author.username} in ${message.channel.guild}#${message.channel.name}`)
                const lambda = new AWS.Lambda({ region: 'ca-central-1' })
                lambda.invoke({ FunctionName: 'minecraft-shipwreck-startup' }).promise()
                    .then(data => {
                        console.log(`successfully started server (status code: ${data.StatusCode})`)
                        message.reply("Aye aye cap'n!")
                    })
                    .catch(e => {
                        console.error(e)
                        message.reply("Aaaaaarrrggghhhhh! 🏴‍☠️ couldn't start the server...")
                    })
            } else if (message.content === '!ping') {
                message.reply("pong")
            }
        })

        client.login(token)
    })
    .catch(e => console.error(e))