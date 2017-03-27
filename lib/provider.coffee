utility = require './utility'
getCompletions = require './get-completions'
getIssues = require './get-issues'
command = require './command'

module.exports =
  selector: '*'
  inclusionPriority: 2
  suggestionPriority: 2
  excludeLowerPriority: false

  name: 'YouCompleteMe'
  grammarScopes: ['*']
  scope: 'file'
  lintsOnChange: true

  getSuggestions: (context) ->
    return [] unless utility.isEnabledForScope context.editor.getRootScopeDescriptor()
    getCompletions(context).catch utility.notifyError []

  lint: (editor) ->
    return [] unless utility.isEnabledForScope editor.getRootScopeDescriptor()
    return [] unless atom.config.get 'you-complete-me.linterEnabled'
    getIssues(editor).catch utility.notifyError []

  getSuggestionForWord: (editor, text, range) ->
    return null unless utility.isEnabledForScope editor.getRootScopeDescriptor()
    range: range
    callback: -> command.run 'GoTo', range.start, true
