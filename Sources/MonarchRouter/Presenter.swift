//
//  Presenter.swift
//  MonarchRouter
//
//  Created by Eliah Snakin on 15/11/2018.
//  nikans.com
//

import UIKit

/// Any `RoutePresenter` object.
public protocol RoutePresenterType {
    /// Returns the actual presentable object.
    var getPresentable: () -> (UIViewController) { get }

    var isPresentableExists: () -> Bool { get }

    /// Allows to configure the presentable with parameters.
    var setParameters: (_ parameters: RouteParameters, _ presentable: UIViewController) -> Void { get }

    /// Clears up when the node is no longer selected.
    var unwind: (_ presentable: UIViewController) -> Void { get }
}

/// A presenter with enabled modals presentation functionality.
public protocol RoutePresenterCapableOfModalPresentationType {
    /// Callback executed when a modal view is requested to be presented.
    var presentModal: (_ modal: UIViewController, _ over: UIViewController) -> Void { get }

    /// Callback executed when a presenter is required to close its modal.
    var dismissModal: (_ modal: UIViewController) -> Void { get }
}

/// Used to present the endpoint.
public struct RoutePresenter: RoutePresenterType, RoutePresenterCapableOfModalPresentationType {
    /// Default initializer for RoutePresenter.
    /// - parameter getPresentable: Callback returning a Presentable object.
    /// - parameter setParameters: Optional callback to configure a Presentable with given `RouteParameters`. Don't set if the Presentable conforms to `RouteParametrizedPresentable`.
    /// - parameter presentModal: Optional callback to define modals presentation. Default behaviour if undefined.
    /// - parameter dismissModal: Optional callback to define modals dismissal. Default behaviour if undefined.
    /// - parameter unwind: Optional callback executed when the Presentable is no longer presented.
    public init(
        getPresentable: @escaping () -> (UIViewController),
        isPresentableExists: @escaping () -> (Bool),
        setParameters: ((_ parameters: RouteParameters, _ presentable: UIViewController) -> Void)? = nil,
        presentModal: ((_ modal: UIViewController, _ over: UIViewController) -> Void)? = nil,
        dismissModal: ((_ modal: UIViewController) -> Void)? = nil,
        unwind: ((_ presentable: UIViewController) -> Void)? = nil
    ) {
        self.getPresentable = getPresentable
        self.isPresentableExists = isPresentableExists

        if let setParameters = setParameters {
            self.setParameters = setParameters
        } else {
            self.setParameters = { parameters, presentable in
                guard let presentable = presentable as? RouteParametrizedPresentable else { return }
                presentable.configure(routeParameters: parameters)
            }
        }

        if let presentModal = presentModal {
            self.presentModal = presentModal
        } else {
            self.presentModal = { modal, parent in
                parent.present(modal, animated: true)
            }
        }

        if let dismissModal = dismissModal {
            self.dismissModal = dismissModal
        } else {
            self.dismissModal = { modal in
                modal.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }

        if let unwind = unwind {
            self.unwind = unwind
        }
    }

    public var presentModal: (_ modal: UIViewController, _ over: UIViewController) -> Void = { _, _ in }
    public var dismissModal: ((_ modal: UIViewController) -> Void) = { _ in }

    public let getPresentable: () -> (UIViewController)
    public let isPresentableExists: () -> Bool

    public var setParameters: (_ parameters: RouteParameters, _ presentable: UIViewController) -> Void = { _, _ in }
    public var unwind: (_ presentable: UIViewController) -> Void = { _ in }

    /// A lazy wrapper around a Presenter creation function that wraps presenter scope, but the Presentable does not get created until invoked.
    /// - parameter getPresentable: Autoclosure returning a Presentable object.
    /// - parameter setParameters: Optional callback to configure a Presentable with given `RouteParameters`. Don't set if the Presentable conforms to `RouteParametrizedPresentable`.
    /// - parameter presentModal: Optional callback to define modals presentation. Default behaviour if undefined.
    /// - parameter dismissModal: Optional callback to define modals dismissal. Default behaviour if undefined.
    /// - parameter unwind: Optional callback executed when the Presentable is no longer presented.
    /// - returns: RoutePresenter
    public static func lazyPresenter(
        _ getPresentable: @escaping () -> (UIViewController),
        setParameters: ((_ parameters: RouteParameters, _ presentable: UIViewController) -> Void)? = nil,
        presentModal: ((_ modal: UIViewController, _ over: UIViewController) -> Void)? = nil,
        dismissModal: ((_ modal: UIViewController) -> Void)? = nil,
        unwind: ((_ presentable: UIViewController) -> Void)? = nil
    ) -> RoutePresenter {
        weak var presentable: UIViewController?

        let maybeCachedPresentable: () -> (UIViewController) = {
            if let cachedPresentable = presentable {
                return cachedPresentable
            }

            let newPresentable = getPresentable()
            presentable = newPresentable
            return newPresentable
        }
        
        let isPresentableExists: () -> Bool = {
            presentable != nil
        }

        let presenter = RoutePresenter(getPresentable: maybeCachedPresentable,
                                       isPresentableExists: isPresentableExists,
                                       setParameters: setParameters,
                                       presentModal: presentModal,
                                       dismissModal: dismissModal,
                                       unwind: unwind)

        return presenter
    }

    /// An autoclosure lazy wrapper around a Presenter creation function that wraps presenter scope, but the Presentable does not get created until invoked.
    /// - parameter getPresentable: Autoclosure returning a Presentable object.
    /// - parameter setParameters: Optional callback to configure a Presentable with given `RouteParameters`. Don't set if the Presentable conforms to `RouteParametrizedPresentable`.
    /// - parameter presentModal: Optional callback to define modals presentation. Default behaviour if undefined.
    /// - parameter dismissModal: Optional callback to define modals dismissal. Default behaviour if undefined.
    /// - parameter unwind: Optional callback executed when the Presentable is no longer presented.
    /// - returns: RoutePresenter
    public static func lazyPresenter(
        wrap getPresentable: @escaping @autoclosure () -> (UIViewController),
        setParameters: ((_ parameters: RouteParameters, _ presentable: UIViewController) -> Void)? = nil,
        presentModal: ((_ modal: UIViewController, _ over: UIViewController) -> Void)? = nil,
        dismissModal: ((_ modal: UIViewController) -> Void)? = nil,
        unwind: ((_ presentable: UIViewController) -> Void)? = nil
    ) -> RoutePresenter {
        weak var presentable: UIViewController?

        let maybeCachedPresentable: () -> (UIViewController) = {
            if let cachedPresentable = presentable {
                return cachedPresentable
            }

            let newPresentable = getPresentable()
            presentable = newPresentable
            return newPresentable
        }
        
        let isPresentableExists: () -> Bool = {
            presentable != nil
        }

        let presenter = RoutePresenter(getPresentable: maybeCachedPresentable,
                                       isPresentableExists: isPresentableExists,
                                       setParameters: setParameters,
                                       presentModal: presentModal,
                                       dismissModal: dismissModal,
                                       unwind: unwind)

        return presenter
    }
}
