provider = require './provider'
handler = require './handler'
config = require './config'
event = require './event'
menu = require './menu'

activate = ->
  event.register()
  menu.register()
  return

deactivate = ->
  event.deregister()
  menu.deregister()
  handler.reset()
  return

module.exports =
  config: config
  activate: activate
  deactivate: deactivate
  provide: -> provider
  provideLinter: -> provider
