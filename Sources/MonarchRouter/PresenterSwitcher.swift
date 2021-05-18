//
//  PresenterSwitcher.swift
//  MonarchRouter
//
//  Created by Eliah Snakin on 20/11/2018.
//  nikans.com
//

import UIKit



/// Can be used to switch top level app sections.
public struct RoutePresenterSwitcher: RoutePresenterType
{
    /// Initializer for Switcher type RoutePresenter.
    /// - parameter getPresentable: Callback returning a Presentable.
    /// - parameter setOptionSelected: Sets the specified option as currently selected.
    public init(
        getPresentable: @escaping () -> (UIViewController),
        isPresentableExists: @escaping () -> (Bool),
        setOptionSelected: @escaping  (_ option: UIViewController) -> ()
    ) {
        self.getPresentable = getPresentable
        self.isPresentableExists = isPresentableExists
        self.setOptionSelected = setOptionSelected
    }
    
    
    /// Sets the specified option as currently selected.
    public let setOptionSelected: (_ option: UIViewController) -> ()
    
    
    
    /// A lazy wrapper around a Presenter creation function that wraps presenter scope, but the Presentable does not get created until invoked.
    /// - parameter createPresentable: Callback that returns the Presentable item.
    /// - parameter setOptionSelected: Sets the specified option as currently selected.
    /// - returns: RoutePresenter
    public static func lazyPresenter(
        _ createPresentable: @escaping () -> (UIViewController),
        setOptionSelected: @escaping  (_ option: UIViewController) -> ()
    ) -> RoutePresenterSwitcher
    {
        weak var presentable: UIViewController? = nil
        
        let maybeCachedPresentable: () -> (UIViewController) = {
            if let cachedPresentable = presentable {
                return cachedPresentable
            }
            
            let newPresentable = createPresentable()
            presentable = newPresentable
            return newPresentable
        }
        
        let isPresentableExists: () -> Bool = {
            presentable != nil
        }

        return RoutePresenterSwitcher(getPresentable: maybeCachedPresentable,
                                      isPresentableExists: isPresentableExists,
                                      setOptionSelected: setOptionSelected)
    }
    
    
    // Immutable, since either configured during init, or doesn't apply.
    public let getPresentable: () -> (UIViewController)
    public let isPresentableExists: () -> Bool
    public let setParameters: (_ parameters: RouteParameters, _ presentable: UIViewController) -> () = { _,_ in }
    public let unwind: (_ presentable: UIViewController) -> () = { _ in }
}
