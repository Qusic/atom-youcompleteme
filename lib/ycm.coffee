handler = require './handler'
provider = require './provider'
config = require './config'
menu = require './menu'
dispatch = require './dispatch'

configObserver = null

activate = ->
  configObserver = atom.config.observe 'you-complete-me', handler.reset
  menu.register()

deactivate = ->
  configObserver?.dispose()
  menu.deregister()
  handler.reset()
  dispatch.dispose()

module.exports =
  config: config
  activate: activate
  deactivate: deactivate
  provide: -> provider
  provideLinter: -> provider
