child_process = require 'child_process'
fs = require 'fs'
path = require 'path'
process = require 'process'

debug = require './debug'

packagePath = path.resolve atom.packages.resolvePackagePath('you-complete-me')
dependencies = [{
  name: 'ycmd'
  repo: 'https://github.com/Qusic/ycmd.git'
  commit: '5796f7d3bccd7050384c4cc710845351bcd416e2'
  extraCheck: (dependencyPath) ->
    versionScript = '''
      from sys import stdout
      from ycm_client_support import YcmCoreVersion
      print YcmCoreVersion()
    '''
    requiredVersion = '17'
    spawn 'python', ['-c', versionScript], dependencyPath, requiredVersion
  extraWarning: 'Ycmd native parts have to be recompiled before it works.'
}]

spawn = (command, args, cwd, output) -> new Promise (fulfill, reject) ->
  debug.log 'CMD', command, args, cwd
  child = child_process.spawn command, args, cwd: cwd
  stdout = ''
  stderr = ''
  child.stdout.on 'data', (data) ->
    data = data.toString()
    stdout += data
    debug.log 'CMD', data
  child.stderr.on 'data', (data) ->
    data = data.toString()
    stderr += data
    debug.log 'CMD', data
  child.on 'close', (code) ->
    if output?
      fulfill code is 0 and stdout.trim() is output.trim()
    else
      if code is 0
        fulfill stdout
      else
        reject new Error "#{command} exited with code #{code} and stderr: #{stderr}"
  child.on 'error', (error) ->
    reject error

updateDependency = ({name, repo, commit, extraCheck, extraWarning}) ->
  dependencyPath = path.resolve(packagePath, name)
  extraCheck ?= -> true

  check = ->
    checkHead = spawn('git', ['rev-parse', 'HEAD'], dependencyPath, commit).catch (error) -> false
    checkExtra = Promise.resolve(dependencyPath).then(extraCheck).catch (error) -> false
    Promise.all [
      checkHead
      checkExtra
    ]

  install = ->
    clone = -> spawn 'git', ['clone', repo], packagePath
    fetch = -> spawn 'git', ['fetch'], dependencyPath
    checkout = -> spawn 'git', ['checkout', commit], dependencyPath
    submodule = -> spawn 'git', ['submodule', 'update', '--init', '--recursive'], dependencyPath
    remove = ->
      if process.platform is 'win32'
        spawn('rmdir', ['/s', '/q', dependencyPath]).catch (error) ->
      else
        spawn('rm',  ['-rf', dependencyPath]).catch (error) ->
    Promise.resolve()
      .then fetch
      .catch ->
        Promise.resolve()
          .then remove
          .then clone
      .then checkout
      .then submodule

  Promise.resolve()
    .then check
    .then ([headPassed, extraPassed]) ->
      if headPassed
        if not extraPassed
          atom.notifications.addWarning "[YCM] #{extraWarning}"
      else
        atom.notifications.addInfo "[YCM] Updating #{name}..."
        Promise.resolve()
          .then install
          .then check
          .then ([headPassed, extraPassed]) ->
            if headPassed
              if extraPassed
                atom.notifications.addSuccess "[YCM] #{name} updated."
              else
                atom.notifications.addWarning "[YCM] #{extraWarning}"
            else
              throw new Error 'Update check failed.'
    .catch (error) ->
      atom.notifications.addError "[YCM] Failed to update #{name}.", detail: "#{error.message}\n#{error.stack}"

updateDependencies = ->
  Promise.all(updateDependency dependency for dependency in dependencies)

module.exports = updateDependencies
