//
//  BaseViewModel.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/22/26.
//

import Foundation
import OSLog
import Observation
import Combine

protocol MVIContract {
    associatedtype IFIntent: enumDescribable
    associatedtype IFState: CustomStringConvertible & Withable
    associatedtype IFEffect: enumDescribable
    
    var isLoading: Bool { get }
    
    func trigger(_ intent: IFIntent)
}

protocol enumDescribable: CustomStringConvertible {}

extension enumDescribable {
    var description: String {
        return "냥냥이!"
    }
}

// MARK: - 2. Base Class (@Observable + IF Naming)
@Observable
class BaseViewModel<IFIntent, IFState, IFEffect>: MVIContract
where IFIntent: enumDescribable, IFState: CustomStringConvertible & Withable , IFEffect: enumDescribable {
    
    private(set) var state: IFState
    
    private let effectSubject = PassthroughSubject<IFEffect, Never>()
    var effectPublisher: AnyPublisher<IFEffect, Never> {
        effectSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    var cancellables = Set<AnyCancellable>()
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "App", category: "ViewModel")
    
    var isLoading: Bool = false
    private var managedTasks: [Task<Void, Never>] = []

    init(initialState: IFState) {
        self.state = initialState
    }

    deinit {
        managedTasks.forEach { $0.cancel() }
    }

    func trigger(_ intent: IFIntent) {
        logger.debug("[\(String(describing: type(of: self)))] ➡️ [INTENT]: \(intent.description)")
        handleIntent(intent)
    }
    
    func handleIntent(_ intent: IFIntent) {
        fatalError("handleIntent(_:) must be overridden")
    }

    func updateState(_ newState: IFState) {
        self.state = newState
        logger.debug("[\(String(describing: type(of: self)))] ➡️ [STATE]: \(newState.description)")
    }

    func postEffect(_ effect: IFEffect) {
        logger.debug("[\(String(describing: type(of: self)))] ➡️ [EFFECT]: \(effect.description)")
        effectSubject.send(effect)
    }

    func withLoading(cancellable: Bool = true, _ action: @escaping () async -> Void) {
        isLoading = true
        let task = Task { [weak self] in
            defer { self?.isLoading = false }
            await action()
        }
        if cancellable {
            managedTasks.append(task)
        }
    }
}
