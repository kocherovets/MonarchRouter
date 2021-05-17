//
//  Presenters.swift
//  MonarchRouterExample
//
//  Created by Eliah Snakin on 16/11/2018.
//  nikans.com
//

import UIKit
import MonarchRouter
import Differ

class StabSwitcherVC: UIViewController {
    
}

// MARK: - App sections' switcher

/// Presenter for top level app sections' switcher.
/// It doesn't actually have any Presentable, setting the window's rootViewController via a callback instead.
/// This one is not lazy, because it's unnecessasy.
func sectionsSwitcherRoutePresenter(_ setRootView: @escaping (UIViewController)->()) -> RoutePresenterSwitcher
{
    var rootPresentable: UIViewController?
    
    return RoutePresenterSwitcher(
        getPresentable: {
            guard let vc = rootPresentable
                else {
                return StabSwitcherVC()
//                fatalError("Impossible to get Presentable for the Switcher type root RoutingNode. Probably there's no other RoutingNode resolving the Request?")
            }
            return vc
        },
        setOptionSelected: { option in
            rootPresentable = option
            setRootView(option)
        }
    )
}



// MARK: - Tab bar

/// Describes the view and action for a tab bar item.
typealias TabBarItemDescription = (title: String, icon: UIImage?, request: AppRoutingRequest)

/// Mock Tab Bar Controller delegate that dispatch routes on tap.
class ExampleTabBarDelegate: NSObject, UITabBarControllerDelegate
{
    init(optionsDescriptions: [TabBarItemDescription], router: ProvidesRouteDispatch) {
        self.optionsDescriptions = optionsDescriptions
        self.router = router
    }
    
    let optionsDescriptions: [TabBarItemDescription]
    let router: ProvidesRouteDispatch
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController)
    {
        let index = tabBarController.selectedIndex
        guard optionsDescriptions.count > index else { return }
        router.dispatch(optionsDescriptions[index].request, options: [.junctionsOnly])
    }
}


/// Lazy Presenter for a Tab Bar Controller with a delegate.
func lazyTabBarRoutePresenter(optionsDescription: [TabBarItemDescription], router: ProvidesRouteDispatch) -> RoutePresenterFork
{
    var tabBarDelegate: ExampleTabBarDelegate!
    
    return RoutePresenterFork.lazyPresenter({
            let tabBarController = UITabBarController()
            tabBarDelegate = ExampleTabBarDelegate(optionsDescriptions: optionsDescription, router: router)
            tabBarController.delegate = tabBarDelegate
            return tabBarController
        },
        setOptions: { options, container in
            let tabBarController = container as! UITabBarController
            tabBarController.setViewControllers(options, animated: true)
            optionsDescription.enumerated().forEach { i, description in
                guard options.count > i else { return }
                options[i].tabBarItem.title = description.title
                options[i].tabBarItem.image = description.icon
            }
        },
        setOptionSelected: { option, container in
            let tabBarController = container as! UITabBarController
            tabBarController.selectedViewController = option
        }
    )
}


/// Lazy Presenter for a Tab Bar Controller without a delegate.
func unenchancedLazyTabBarRoutePresenter() -> RoutePresenterFork
{
    return RoutePresenterFork.lazyPresenter({
            UITabBarController()
        },
        setOptions: { options, container in
            let tabBarController = container as! UITabBarController
            tabBarController.setViewControllers(options, animated: true)
        },
        setOptionSelected: { option, container in
            let tabBarController = container as! UITabBarController
            tabBarController.selectedViewController = option
        }
    )
}



// MARK: - Navigation stack

// Lazy Presenter for a Navigation Controller.
func lazyNavigationRoutePresenter() -> RoutePresenterStack
{
    return RoutePresenterStack.lazyPresenter({
        UINavigationController()
    },
    setStack: { (newStack, container) in
        let navigationController = container as! UINavigationController
        let currentStack = navigationController.viewControllers
        
        // same, do nothing
        if currentStack.count == newStack.count, currentStack.last == newStack.last {
            return
        }
        
        // only one, pop to root
        if newStack.count == 1 && currentStack.count > 1 {
            navigationController.popToRootViewController(animated: true)
        }
        
        // pop
        if currentStack.count > newStack.count {
            navigationController.setViewControllers(newStack, animated: true)
        }
        
        // push
        else {
            let diff = patch(from: currentStack, to: newStack)
            diff.forEach({ change in
                switch change {
                    
                case .insertion(let idx, let vc):
                    if idx == newStack.count - 1 {
                        navigationController.pushViewController(vc, animated: true)
                    } else {
                        navigationController.viewControllers.insert(vc, at: idx)
                    }
                    
                case .deletion(let idx):
                    navigationController.viewControllers.remove(at: idx)
                }
            })
        }
    },
    prepareRootPresentable: { (rootPresentable, container) in
        let navigationController = container as! UINavigationController
        guard navigationController.viewControllers.count == 0 else { return }
        navigationController.setViewControllers([rootPresentable], animated: false)
    })
}



// MARK: - General

func lazyPresenter(for endpoint: EndpointViewControllerId, router: ProvidesRouteDispatch) -> RoutePresenter
{
    return RoutePresenter.lazyPresenter(wrap: buildEndpoint(endpoint, router: router))
}

// MARK: - General

func lp(for endpoint: EndpointViewControllerId, router: ProvidesRouteDispatch) -> RoutePresenter
{
    return RoutePresenter.lazyPresenter(wrap: buildEndpoint(endpoint, router: router))
}
