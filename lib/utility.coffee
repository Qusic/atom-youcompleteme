getEditorData = (editor = atom.workspace.getActiveTextEditor(), scopeDescriptor = editor.getRootScopeDescriptor(), bufferPosition = editor.getCursorBufferPosition()) ->
  curedit = atom.workspace.getTextEditors().filter (x) -> x isnt editor and getFileStatus(x.getPath(), 'visit') and x.isModified()
  curedit.unshift editor
  filedatas = curedit.map (x) ->
    filepath: x.getPath()
    contents: x.getText()
    filetypes: [(if x is editor then scopeDescriptor else x.getRootScopeDescriptor())
      .getScopesArray()[0].split('.').pop()]

  Promise.resolve {filedatas, bufferPosition}

getEditorFiletype = (editor = atom.workspace.getActiveTextEditor(),
                     scopeDescriptor = editor.getRootScopeDescriptor()) ->
  return [scopeDescriptor.getScopesArray()[0].split('.').pop()]

buildRequestParameters = (filedatas, bufferPosition = [0, 0]) ->
  parameters =
    filepath: filedatas[0].filepath
    line_num: bufferPosition.row + 1
    column_num: bufferPosition.column + 1
    file_data: {}
  for x in filedatas
    parameters.file_data[x.filepath] =
      contents: x.contents
      filetypes: x.filetypes
  return parameters

jsonUnicodeEscaper = (key, value) ->
  if typeof value is 'string'
    escapedString = ''
    for i in [0...value.length]
      char = value.charAt i
      charCode = value.charCodeAt i
      escapedString += if charCode < 0x80 then char else ('\\u' + ('0000' + charCode.toString 16).substr -4)
    return escapedString

# TODO: remove this code
fileStatus = {}
setFileStatus = (filepath, status, value) -> if filepath of fileStatus then fileStatus[filepath][status] = value else fileStatus[filepath] = {status: value}
delFileStatus = (filepath) -> delete fileStatus[filepath]
getFileStatus = (filepath, status) -> fileStatus[filepath]?[status]
resetFileStatus = -> fileStatus = {}

class FileStatusDB
  constructor: (@db = {}) ->
  setStatus: (filepath, status, value) -> (@db[filepath] || @db[filepath] = {})[status] = value
  delFileEntry: (filepath) -> delete @db[filepath]
  getStatus: (filepath, status) -> @db[filepath]?[status]
  length: -> Object.keys(@db).length
  clear: -> @db = {}


module.exports =
  getEditorData: getEditorData
  jsonUnicodeEscaper: jsonUnicodeEscaper
  getEditorFiletype: getEditorFiletype
  buildRequestParameters: buildRequestParameters
  setFileStatus: setFileStatus
  delFileStatus: delFileStatus
  getFileStatus: getFileStatus
  resetFileStatus: resetFileStatus
  FileStatusDB: FileStatusDB
