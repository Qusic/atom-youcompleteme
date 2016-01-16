handler = require './handler'
config = require './config'
menu = require './menu'

provider = null
configObserver = null

activate = ->
  provider = require './provider'
  configObserver = atom.config.observe 'you-complete-me', handler.reset
  menu.register()
  return

deactivate = ->
  configObserver?.dispose()
  menu.deregister()
  handler.reset()
  return

module.exports =
  config: config
  activate: activate
  deactivate: deactivate
  provide: -> provider
  provideLinter: -> provider
