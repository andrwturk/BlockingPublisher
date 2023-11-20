# BlockingPublisher — test your Combine code easily

## Sneak peak

```swift
// testing sequence of values
let arrayPublisher = [1, 2, 3, 4, 5].publisher
let array = try? arrayPublisher.toBlocking().toArray()
XCTAssertEqual(array, [1, 2, 3, 4, 5])

// testing single value
let arrayPublisher = [1, 2, 3, 4, 5].publisher
let first = try? arrayPublisher.toBlocking().first()
XCTAssertEqual(first, 1)
let last = try? arrayPublisher.toBlocking().last()
XCTAssertEqual(last, 5)
```

## Introduction

BlockingPublisher is RxBlocking inspired implementation of blocking observable which is very useful to write unit tests in an easy and natural way. 

## Contributing
Your contributions are welcome! Feel free to open issues for feature requests or bug reports, and submit pull requests for new features or fixes. For major changes, it's always good to open an issue first to discuss what you would like to change.
