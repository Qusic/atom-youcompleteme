handler = require './handler'
provider = require './provider'
config = require './config'
menu = require './menu'
updateDependencies = require './update-dependencies'
dispatch = require './dispatch'

configObserver = null

activate = ->
  configObserver = atom.config.observe 'you-complete-me', handler.reset
  menu.register()
  updateDependencies()

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
