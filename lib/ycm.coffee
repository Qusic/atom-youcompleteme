handler = require './handler'
provider = require './provider'
config = require './config'
menu = require './menu'
updateDependencies = require './update-dependencies'

configObserver = null

activate = ->
  configObserver = atom.config.observe 'you-complete-me', handler.reset
  menu.register()
  updateDependencies()

deactivate = ->
  configObserver?.dispose()
  menu.deregister()
  handler.reset()

module.exports =
  config: config
  activate: activate
  deactivate: deactivate
  provide: -> provider
  provideLinter: -> provider
