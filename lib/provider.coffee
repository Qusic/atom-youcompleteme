getSuggestions = require './get-suggestions'
getCompileEvents = require './get-compile-events'

module.exports =
  selector: '.source.c, .source.cpp, .source.objc, .source.objcpp, .source.python'
  disableForSelector: '.source.c .comment, .source.cpp .comment, .source.objc .comment, .source.objcpp .comment, .source.python .comment'
  inclusionPriority: 1
  excludeLowerPriority: false

  name: 'YCM Linter'
  grammarScopes: ['source.c', 'source.cpp', 'source.objc', 'source.objcpp']
  scope: 'file' # or 'project'
  lintOnFly: atom.config.get 'you-complete-me.lintDuringEdit' # must be false for scope: 'project'

  getSuggestions: (context) ->
    getSuggestions(context).catch (error) ->
      console.error '[YCM-ERROR]', error
      return []

  lint: (editor) ->
    getCompileEvents(editor).catch (error) ->
      console.error '[YCM-ERROR]', error
      return []
