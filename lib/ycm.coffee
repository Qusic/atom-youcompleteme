provider = require './provider'
handler = require './handler'
config = require './config'
event = require './event'
command = require './command'

activate = ->
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
