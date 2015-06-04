# Atom YouCompleteMe package

[AutoComplete+](https://github.com/atom-community/autocomplete-plus) Provider for [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)

## Previews

![](https://cloud.githubusercontent.com/assets/2141853/7626423/79024212-fa3b-11e4-941e-e014a8e5b0df.gif)
![](https://cloud.githubusercontent.com/assets/2141853/7626422/7901f352-fa3b-11e4-8007-82ab514fb8e9.gif)

## Usage

```
# Install the package
# Open Atom and it will download ycmd automatically.

# Build C++ components of ycmd
# Sometimes you have to rebuild them after upgrading the package.
# You will get notified in Atom if that happens.
cd ~/.atom/packages/you-complete-me/ycmd
git submodule update --init --recursive
./ycmd/build.py [--clang-completer] [--omnisharp-completer] [--gocode-completer]
```

You may notice that this package uses a fork of ycmd instead of the original one. It is necessary for all the awesome features because the upstream does not merge pull requests quickly enough or some essential changes are specific to Atom client and will not be merged into the upstream.

For detailed instructions and troubleshooting on building ycmd, see [YouCompleteMe's README](https://github.com/Valloric/YouCompleteMe/blob/master/README.md#installation).
