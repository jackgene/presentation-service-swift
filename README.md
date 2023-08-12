# Presentation Service in Swift

Build and run:
```shell
swift run -c release Run present --port 8973 --html-path (path to deck.html)
```

Build then run:
```shell
swift build -c release
.build/release/Run present --port 8973 --html-path (path to deck.html)
```

When benchmarking, run the following to increase macOS limits:
```shell
ulimit -n 2048
```

### Background
This is a Vapor project, created by running:
```shell
vapor new PresentationService -n --output presentation-service-swift
```
