# Go Plugin

The go plugin provides some extra niceties for using miide with
the Go programming language. The main thing this plugin does is
run `gofmt` , `goimports` , `govet` and `golint` for you automatically on save.

## Commands

|Command                    |Action                                             |
|---------------------------|---------------------------------------------------|
|`golist [package]`         |List standar library packages or filter package    |
|`godoc [package][.method]` |List documentation summary of package name, method |

## Bindings

|Key |Action             |Comments                               |
|----|-------------------|---------------------------------------|
|F7  |`modernize`        |run modernize over code                |
|F9  |`toggle gofmt`     |on/off gofmt on save                   |
|F10 |`toggle govet`     |on/off go vet on save                  |
|F11 |`toggle golint`    |on/off golint, requeires golangci-lint |
|F12 |`toggle goimports` |on/off automatic imports               |

## Notes on golangci-lint

Recommended version : 2+

Basic `.golangci.yml` config file

```yaml
version: "2"
linters:
    default: fast
    enable:
        - gomodguard_v2
    disable:
        - mnd
        - wsl
        - gomodguard
    exclusions:
        paths:
            - _test.go
```
