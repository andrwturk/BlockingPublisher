//
//  BlockingPublisher.swift
//  BlockingPublisher
//
//  Created by Andrii Turkin on 20.11.23.
//

import Foundation
import Combine

public final class BlockingPublisher<Output, Failure: Error> {
    private let publisher: AnyPublisher<Output, Failure>
    private var cancellable: AnyCancellable?
    private let timeout: TimeInterval

    init<P: Publisher>(_ publisher: P, timeout: TimeInterval) where P.Output == Output, P.Failure == Failure {
        self.publisher = publisher.eraseToAnyPublisher()
        self.timeout = timeout
    }
}

extension BlockingPublisher {
    
    /// Provides sequence of elements in publisher.
    /// - Returns: Array of items in publisher from first to complete
    /// or number of elements until timeout
    /// - Throws: If sequence ends with error
    public func toArray() throws -> [Output] {
        let result = materialize()
        return try elementsOrThrow(result)
    }

    /// Provides sequence of elements in publisher.
    /// - Returns: First item in publisher
    /// - Throws: If sequence ends with error
    public func first() throws -> Output? {
        let result = materialize()
        return try elementsOrThrow(result).first
    }

    /// Provides sequence of elements in publisher.
    /// - Returns: Last item in publisher
    /// - Throws: If sequence ends with error
    public func last() throws -> Output? {
        let result = materialize()
        return try elementsOrThrow(result).last
    }
    
    /// Waits for sequence to complete
    /// - Returns: Materialized output
    private func materialize() -> MaterializedSequenceResult<Output> {
        var elements = [Output]()
        var completionError: Failure?
        let semaphore = DispatchSemaphore(value: 0)

        cancellable = publisher
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    completionError = error
                }
                semaphore.signal()
            }, receiveValue: { value in
                elements.append(value)
            })

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            return .failed(elements: elements, error: BlockingError.timeout)
        }

        if let error = completionError {
            return .failed(elements: elements, error: error)
        } else {
            return .completed(elements: elements)
        }
    }
    
    /// Returns elements in sequnce or throws error if sequence ends with error
    private func elementsOrThrow(_ result: MaterializedSequenceResult<Output>) throws -> [Output] {
        switch result {
        case .failed(_, let error):
            throw error
        case .completed(let elements):
            return elements
        }
    }
}

/// Helper enum to pack materialized result
enum MaterializedSequenceResult<Output> {
    case completed(elements: [Output])
    case failed(elements: [Output], error: Error)
}

/// Blocking error
enum BlockingError: Error {
    
    /// sequnce ended with timeout
    case timeout
}
