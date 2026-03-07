# Go is managed by mise; GOPATH defaults to ~/go
# Override GOBIN so `go install` puts binaries in ~/go/bin (on PATH)
# instead of mise's internal bin dir
export GOBIN="$HOME/go/bin"
