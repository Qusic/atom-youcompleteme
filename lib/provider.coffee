os = require 'os'
path = require 'path'
{File} = require 'atom'

getSuggestions = require './get-suggestions'
loadExtraConfig = require './load-extra-config'

module.exports =
  selector: '.source.c, .source.cpp, .source.objc, .source.objcpp, .source.python'
  inclusionPriority: 1
  excludeLowerPriority: false

  getSuggestions: (context) ->
    getSuggestions(context).catch (error) ->
      console.error '[YCM-ERROR]', error
