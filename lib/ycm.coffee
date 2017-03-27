{install} = require 'atom-package-deps'

provider = require './provider'
handler = require './handler'
config = require './config'
event = require './event'
command = require './command'

activate = ->
  install('you-complete-me', true)
  event.register()
  command.register()

deactivate = ->
  event.deregister()
  command.deregister()
  handler.reset()

module.exports = {
  config
  activate
  deactivate
  provide: -> provider
  provideLinter: -> provider
  provideHyperclick: -> provider
}
