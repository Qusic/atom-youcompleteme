utility = require './utility'
getCompletions = require './get-completions'
getIssues = require './get-issues'

enabledForScope = (scopeDescriptor) ->


module.exports =
  selector: '*'
  inclusionPriority: 2
  suggestionPriority: 2
  excludeLowerPriority: false

  grammarScopes: ['*']
  scope: 'file'
  lintOnFly: true

  getSuggestions: (context) ->
    return [] unless utility.isEnabledForScope context.scopeDescriptor
    getCompletions(context).catch (error) ->
      console.error '[YCM-ERROR]', error
      return []

  lint: (editor) ->
    return [] unless utility.isEnabledForScope editor.getRootScopeDescriptor()
    getIssues(editor).catch (error) ->
      console.error '[YCM-ERROR]', error
      return []
