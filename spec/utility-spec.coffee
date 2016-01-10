{assurePluginLoadedWithLanguage, openWorkspaceWithEditor, waitsForResolve} = require './utility'
utility = require '../lib/utility'

describe "utility", ->
  [editor] = []

  assurePluginLoadedWithLanguage('c')
  openWorkspaceWithEditor fileExtension='c', (openedEditor) -> editor = openedEditor
  beforeEach ->
    editor.setText("int x = 42;")

  it "should get the editor filetype", ->
    expect(utility.getEditorFiletype(editor)).toEqual(['c'])

  it "should obtain editor data in the correct format", ->
    waitsForResolve (utility.getEditorData editor
        .then (value) ->
          expect(value.filedatas.length).toBe(1)
          finfo = value.filedatas[0]
          expect(finfo.filepath).toMatch(/test\.c/)
          expect(finfo.contents).toEqual('int x = 42;')
          expect(finfo.filetypes).toEqual(['c'])
      )

  it "should be able to build request parameters from editor data", ->
    waitsForResolve (utility.getEditorData editor
        .then ({filedatas, bufferPosition}) ->
          p = utility.buildRequestParameters(filedatas, bufferPosition)
          expect(p.column_num).toBe 12
          expect(p.filepath).toMatch /test\.c/
          expect(p.line_num).toBe 1
          expect(Object.keys(p.file_data).length).toBe 1

          d = p.file_data[Object.keys(p.file_data)[0]]
          expect(d.contents).toEqual "int x = 42;"
          expect(d.filetypes.length).toBe 1
          expect(d.filetypes[0]).toEqual 'c'
      )


  describe "FileStatusDB", ->

    beforeEach ->
      @db = new utility.FileStatusDB()

    it "should support basic file status operations", ->
      [fp, stat, val] = ['x', 'valid', true]

      expect(@db.length()).toBe 0
      expect(@db.getStatus(fp, stat)).toBeUndefined()

      expect(@db.length()).toBe 0
      expect(@db.setStatus(fp, stat, val)).toBe val
      expect(@db.length()).toBe 1

      expect(@db.getStatus(fp, stat)).toBe val
      @db.delFileEntry(fp)
      expect(@db.getStatus(fp, stat)).toBeUndefined()
      expect(@db.length()).toBe 0

      expect(@db.setStatus(fp, stat, val)).toBe val
      expect(@db.length()).toBe 1
      @db.clear()
      expect(@db.length()).toBe 0
