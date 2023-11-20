//
//  BlockingPublisher.swift
//  BlockingPublisher
//
//  Created by Andrii Turkin on 20.11.23.
//

import Foundation
import Combine

final class BlockingPublisher<Output, Failure: Error> {
    private let publisher: AnyPublisher<Output, Failure>
    private var cancellable: AnyCancellable?
    private let timeout: TimeInterval

    init<P: Publisher>(_ publisher: P, timeout: TimeInterval) where P.Output == Output, P.Failure == Failure {
        self.publisher = publisher.eraseToAnyPublisher()
        self.timeout = timeout
    }
}

extension BlockingPublisher {

    func materialize() -> MaterializedSequenceResult<Output> {
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

    func toArray() throws -> [Output] {
        let result = materialize()
        return try elementsOrThrow(result)
    }

    func first() throws -> Output? {
        let result = materialize()
        return try elementsOrThrow(result).first
    }

    func last() throws -> Output? {
        let result = materialize()
        return try elementsOrThrow(result).last
    }

    func single(_ predicate: @escaping (Output) throws -> Bool = { _ in true }) throws -> Output {
        let results = materialize()
        let elements = elementsFiltered(by: predicate, from: results)
        guard elements.count == 1 else {
            throw BlockingError.moreThanOneElement
        }
        return elements[0]
    }

    private func elementsOrThrow(_ result: MaterializedSequenceResult<Output>) throws -> [Output] {
        switch result {
        case .failed(_, let error):
            throw error
        case .completed(let elements):
            return elements
        }
    }

    private func elementsFiltered(by predicate: @escaping (Output) throws -> Bool, from result: MaterializedSequenceResult<Output>) -> [Output] {
            switch result {
            case .completed(let elements):
                return (try? elements.filter(predicate)) ?? []
            case .failed(let elements, _):
                return (try? elements.filter(predicate)) ?? []
            }
        }
}

enum MaterializedSequenceResult<Output> {
    case completed(elements: [Output])
    case failed(elements: [Output], error: Error)
}

enum BlockingError: Error {
    case timeout
    case moreThanOneElement
}
