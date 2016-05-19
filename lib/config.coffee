module.exports =
  pythonExecutable:
    type: 'string'
    default: 'python'
    order: 1
    description: '
      The path to the python executable to launch ycmd with.
    '
  ycmdPath:
    type: 'string'
    default: '/usr/lib/youcompleteme/third_party/ycmd'
    order: 2
    description: '
      The directory containing the `ycmd/default_settings.json` file.
      [Ycmd](https://github.com/Valloric/ycmd) is required for this plugin to work.
    '
  enabledFiletypes:
    type: 'array'
    items: type: 'string'
    default: ['c', 'cpp', 'objc', 'objcpp']
    order: 3
    description: '
      An array of filetypes within we should provide completions and diagnostics.
      They are equivalent to file extensions most of the time.
    '
  linterEnabled:
    type: 'boolean'
    default: true
    order: 4
    description: '
      Disable linter if you do not need those diagnostic messages.
    '
  globalExtraConfig:
    type: 'string'
    default: ''
    order: 5
    description: '
      The fallback extra config file when no `.ycm_extra_conf.py` is found.
      Follow [this link](https://github.com/Valloric/YouCompleteMe#the-gycm_global_ycm_extra_conf-option) for more information.
    '
  confirmExtraConfig:
    type: 'boolean'
    default: true
    order: 6
    description: '
      Whether to ask once before loading an extra config file for safety reason.
      To selectively whitelist or blacklist them, use **Extra Config Globlist** option.
      Follow [this link](https://github.com/Valloric/YouCompleteMe#the-gycm_confirm_extra_conf-option) for more information.
    '
  extraConfigGloblist:
    type: 'array'
    items: type: 'string'
    default: []
    order: 7
    description: '
      Extra config files whitelist and blacklist,
      e.g. `~/dev/*, !~/*` would make it load all `.ycm_extra_conf.py` under `~/dev/` and not to load all other `.ycm_extra_conf.py` under `~/`, without confirmation.
      Follow [this link](https://github.com/Valloric/YouCompleteMe#the-gycm_extra_conf_globlist-option) for more information.
    '
  rustSrcPath:
    type: 'string'
    default: ''
    order: 8
    description: '
      The directory containing the [Rust source code](https://github.com/rust-lang/rust).
      You have also to to add `rust` in **Enabled Filetypes**.
      Follow [this link](https://github.com/Valloric/YouCompleteMe#rust-semantic-completion) for more information.
    '
