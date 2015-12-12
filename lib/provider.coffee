getSuggestions = require './get-suggestions'
getCompileEvents = require './get-compile-events'

module.exports =
  selector: (
    langs = ['.source.c', '.source.cpp', '.source.objc', '.source.objcpp']
    langs.push('.source.python') if not atom.config.get('you-complete-me.pythonSupport')? or atom.config.get 'you-complete-me.pythonSupport'
    langs.push('.source.cs') if not atom.config.get('you-complete-me.csharpSupport')? or atom.config.get 'you-complete-me.csharpSupport'
    langs.push('.source.go') if not atom.config.get('you-complete-me.golangSupport')? or atom.config.get 'you-complete-me.golangSupport'
    langs.join ','
  )
  disableForSelector: '.source.c .comment, .source.cpp .comment, .source.objc .comment, .source.objcpp .comment, .source.python .comment, .source.cs .comment, .source.go .comment'
  inclusionPriority: 1
  excludeLowerPriority: false

  name: 'YCM Linter'
  grammarScopes: (
    langs = ['source.c', 'source.cpp', 'source.objc', 'source.objcpp']
    langs.push('source.cs') if not atom.config.get('you-complete-me.csharpSupport')? or atom.config.get 'you-complete-me.csharpSupport'
    langs
  )
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
