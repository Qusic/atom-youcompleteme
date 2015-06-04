handler = require './handler'
provider = require './provider'
config = require './config'
updateDependencies = require './update-dependencies'

configObserver = null

activate = ->
  configObserver = atom.config.observe 'you-complete-me', -> handler.reset()
  handler.prepare()
  updateDependencies()

deactivate = ->
  configObserver?.dispose()
  handler.reset()

module.exports =
  config: config
  activate: activate
  deactivate: deactivate
  provide: () -> provider
