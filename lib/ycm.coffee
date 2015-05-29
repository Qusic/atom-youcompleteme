handler = require './handler'
provider = require './provider'
config = require './config'
configObserver = null

activate = ->
  configObserver = atom.config.observe 'you-complete-me', -> handler.reset()
  handler.prepare()

deactivate = ->
  configObserver?.dispose()
  handler.reset()

provide = ->
  provider

module.exports =
  config: config
  activate: () -> activate()
  deactivate: () -> deactivate()
  provide: () -> provider
