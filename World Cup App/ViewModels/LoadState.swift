import Foundation

/// What a screen that loads data is currently showing.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}

extension LoadState: Equatable where Value: Equatable {}
