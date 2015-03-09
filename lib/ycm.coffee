module.exports =
  handler: require './ycm-handler'
  provider: require './ycm-provider'
  config: require './ycm-config'

  activate: ->
    @configObserver = atom.config.observe 'you-complete-me', => @handler.reset()
    @handler.prepare()

  deactivate: ->
    @configObserver?.dispose()
    @handler.reset()

  provide: ->
    @provider
