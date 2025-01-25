# Go Plugin

The go plugin provides some extra niceties for using miide with
the Go programming language. The main thing this plugin does is
run `gofmt` , `goimports` and `go buil` for you automatically.

You can run

```
> gofmt
```

```
> goimports
```

```
> gobuild <file or .>
```

If you execute `gobuild`, the build process will be executed on every
save action from here on.

If you want to stop further builds on save, run:

```
> gobuild off
```

To automatically run these when you save the file, use the following
key bindings, to toggle on/off:

F10: `goimports`
F11: `gofmt`
