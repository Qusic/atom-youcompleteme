#!/usr/bin/env coffee

child_process = require 'child_process'
path = require 'path'
process = require 'process'

ycmd =
  repo: 'https://github.com/Qusic/ycmd.git'
  commit: 'ed958ea203e651942a346725a0194118969ac398'
  root_dir: __dirname
  ycmd_dir: path.resolve __dirname, 'ycmd'

  spawn: (command, args, cwd = @root_dir) ->
    child_process.spawnSync command, args, {
      cwd: cwd
      encoding: 'utf8'
    }

  clone: () ->
    result = @spawn 'git', ['clone', @repo], @root_dir
    return result.status is 0
  fetch: () ->
    result = @spawn 'git', ['fetch'], @ycmd_dir
    return result.status is 0
  checkout: () ->
    result = @spawn 'git', ['checkout', @commit], @ycmd_dir
    return result.status is 0
  submodule: () ->
    result = @spawn 'git', ['submodule', 'update', '--init', '--recursive'], @ycmd_dir
    return result.status is 0
  remove: () ->
    result = @spawn 'rm', ['-rf', @ycmd_dir]
    return result.status is 0

  version: () ->
    result = @spawn 'python', ['-c', '''
      from sys import stdout
      from ycm_client_support import YcmCoreVersion
      stdout.write(str(YcmCoreVersion()))
    '''], @ycmd_dir
    return if result.status is 0 then result.stdout else null

unless (ycmd.fetch() or (ycmd.remove() and ycmd.clone())) and ycmd.checkout() and ycmd.submodule()
  console.error 'Failed to fetch ycmd from github.'
  process.exit 1

unless ycmd.version() is '17'
  console.warn 'Ycmd native parts have to be recompiled before this package works.'
  process.exit 0

console.log 'Everything looks fine. You are good to go!'
process.exit 0
