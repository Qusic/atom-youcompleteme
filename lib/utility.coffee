os = require 'os'
path = require 'path'
{File, Point} = require 'atom'

getWorkingDirectory = ->
  projects = atom.project.getPaths()
  activeFile = atom.workspace.getActiveTextEditor()?.getPath()
  if activeFile?
    projects.find((project) -> activeFile.startsWith project) or path.dirname activeFile
  else
    projects[0] or atom.config.get 'core.projectHome'

getEditorTmpFilepath = (editor) ->
  return path.resolve os.tmpdir(), "AtomYcmBuffer-#{editor.getBuffer().getId()}"

getEditorData = (editor = atom.workspace.getActiveTextEditor()) ->
  filepath = editor.getPath()
  contents = editor.getText()
  filetypes = getScopeFiletypes editor.getRootScopeDescriptor()
  bufferPosition = editor.getCursorBufferPosition()
  if filepath?
    return Promise.resolve {filepath, contents, filetypes, bufferPosition}
  else
    return new Promise (fulfill, reject) ->
      filepath = getEditorTmpFilepath editor
      file = new File filepath
      file.write contents
        .then -> fulfill {filepath, contents, filetypes, bufferPosition}
        .catch (error) -> reject error

getScopeFiletypes = (scopeDescriptor = atom.workspace.getActiveTextEditor().getRootScopeDescriptor()) ->
  return scopeDescriptor.getScopesArray().map (scope) -> scope.split('.').pop()

buildRequestParameters = (filepath, contents, filetypes = [], bufferPosition = [0, 0]) ->
  convertFiletypes = (filetypes) ->
    filetypes.map((filetype) -> switch filetype
      when 'js', 'jsx' then 'javascript'
      else filetype
    ).filter (filetype, index, filetypes) -> filetypes.indexOf(filetype) is index
  bufferPosition = Point.fromObject(bufferPosition)
  workingDir = getWorkingDirectory()
  parameters =
    filepath: filepath
    working_dir: workingDir
    line_num: bufferPosition.row + 1
    column_num: bufferPosition.column + 1
    file_data: {}
  parameters.file_data[filepath] = {contents, filetypes: convertFiletypes filetypes}
  atom.workspace.getTextEditors()
    .filter (editor) ->
      return false unless editor.isModified()
      otherFilepath = editor.getPath()
      otherFilepath? and otherFilepath isnt filepath and otherFilepath.startsWith workingDir
    .forEach (editor) ->
      parameters.file_data[editor.getPath()] =
        contents: editor.getText()
        filetypes: convertFiletypes getScopeFiletypes editor.getRootScopeDescriptor()
  return parameters

isEnabledForScope = (scopeDescriptor) ->
  return true

notifyError = (result) -> (error) ->
  atom.notifications.addError "[TabNine] #{error.name}", detail: "#{error.stack}"
  result

debugLog = (category, message...) ->
  console.debug "[TabNine-#{category}]", message... if atom.inDevMode()

module.exports = {
  getWorkingDirectory
  getEditorTmpFilepath
  getEditorData
  getScopeFiletypes
  buildRequestParameters
  isEnabledForScope
  notifyError
  debugLog
}
