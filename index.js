const emoji = require('node-emoji')
const inquirer = require('inquirer')
const config = require('./config')
const command = require('./command')

inquirer.prompt([{
  type: 'confirm',
  name: 'libs',
  message: 'Do you want to proceed?',
  default: false
}]).then(function (answers) {
  ['brew', 'cask', 'npm', 'gem'].forEach( type => {
    if(config[type] && config[type].length){
      console.info(emoji.get('coffee'), ' installing ' + type + ' packages')
      config[type].map(function(item){
        console.info(type+':', item)
        command('. shell/echos.sh && . shell/requirers.sh && require_' + type + ' ' + item, __dirname, function(err, out) {
          if(err) console.error(emoji.get('fire'), err)
        })
      })
    }
  })
})
