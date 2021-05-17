//
//  AppCoordinator.swift
//  MonarchRouterExample
//
//  Created by Eliah Snakin on 16/11/2018.
//  nikans.com
//

import MonarchRouter
import UIKit

class F {
    var router: ProvidesRouteDispatch!

    func book(uuid: String, route: AppRoute = .book, children: [RoutingNodeType] = [], modals: [RoutingNodeType] = []) -> RoutingNodeType {
        RoutingNode(uuid: uuid, lp(for: .book, router: router)).endpoint(route, children: children, modals: modals)
    }

    func story(uuid: String, route: AppRoute = .story, children: [RoutingNodeType] = [], modals: [RoutingNodeType] = []) -> RoutingNodeType {
        RoutingNode(uuid: uuid, lp(for: .story, router: router)).endpoint(route, children: children, modals: modals)
    }
}

fileprivate let f = F()

/// Creating the app's Coordinator hierarchy.
func appCoordinator(router: ProvidesRouteDispatch, setRootView: @escaping (UIViewController) -> Void) -> RoutingNodeType
{
    f.router = router

    return
        // Top level app sections' switcher
        RoutingNode(uuid: "Switcher 1", sectionsSwitcherRoutePresenter(setRootView)).switcher([
            // Login
            RoutingNode(uuid: "Login 2", lp(for: .login, router: router))
                .endpoint(AppRoute.login),

            // Onboarding nav stack
            RoutingNode(uuid: "Onboarding NC 3", lazyNavigationRoutePresenter()).stack([
                // Parametrized welcome page
                RoutingNode(uuid: "Onboarding 4", lp(for: .onboarding, router: router))
                    .endpoint(AppRoute.onboarding),
            ]),

            // Tabbar
            RoutingNode(uuid: "Tabbar 5", lazyTabBarRoutePresenter(
                optionsDescription: [
                    (title: "Today", icon: nil, request: .today),
                    (title: "Books", icon: nil, request: .books),
                    (title: "Profile", icon: nil, request: .profile),
                ],
                router: router)).fork([
                // Today nav stack
                RoutingNode(uuid: "Today NC 6", lazyNavigationRoutePresenter()).stack([
                    // Today
                    RoutingNode(uuid: "Today 7", lp(for: .today, router: router))
                        .endpoint(AppRoute.today, children: [
                            // All news
                            RoutingNode(uuid: "All News 8", lp(for: .allNews, router: router))
                                .endpoint(AppRoute.allNews),

                        ], modals: [
                            // Story
                            f.story(uuid: "Story 9", modals: [f.story(uuid: "Story 10")]),
                        ]),
                ]),

                // Books nav stack
                RoutingNode(uuid: "Books NC 11", lazyNavigationRoutePresenter()).stack([
                    // Books
                    RoutingNode(uuid: "Books 12", lp(for: .books, router: router)).endpoint(
                        AppRoute.books,
                        children: [
                            f.book(uuid: "Book 13", children: [f.book(uuid: "Book 14")]),
                        ]),
                ]),

                // Profile nav stack
                RoutingNode(uuid: "Profile NC 15", lazyNavigationRoutePresenter()).stack([
                    // Profile
                    RoutingNode(uuid: "Profile 16", lp(for: .profile, router: router))
                        .endpoint(AppRoute.profile, modals: [
                            // Tabbar
                            RoutingNode(uuid: "Orders tabbar 17", lazyTabBarRoutePresenter(
                                optionsDescription: [
                                    (title: "Orders", icon: nil, request: .orders),
                                    (title: "Delivery", icon: nil, request: .deliveryInfo),
                                ],
                                router: router)).fork([
                                // Orders nav stack
                                RoutingNode(uuid: "Orders NC 18", lazyNavigationRoutePresenter()).stack([
                                    // Orders done
                                    RoutingNode(uuid: "Orders 19", lp(for: .orders, router: router))
                                        .endpoint(AppRoute.orders),
                                ]),

                                // Delivery info
                                RoutingNode(uuid: "Ddelivery 20", lp(for: .deliveryInfo, router: router))
                                    .endpoint(AppRoute.deliveryInfo),
                            ]),
                        ]),
                ]),
            ]),
        ])
}

//
//
///// Creating the app's Coordinator hierarchy.
// func appCoordinator(router: ProvidesRouteDispatch, setRootView: @escaping (UIViewController)->()) -> RoutingNodeType
// {
//    return
//        // Top level app sections' switcher
//        RoutingNode(sectionsSwitcherRoutePresenter(setRootView)).switcher([
//
//            // Login
//            RoutingNode(lazyPresenter(for: .login, router: router))
//                .endpoint(AppRoute.login),
//
//            // Onboarding nav stack
//            RoutingNode(lazyNavigationRoutePresenter()).stack([
//
//                // Parametrized welcome page
//                RoutingNode(lazyPresenter(for: .onboarding, router: router))
//                    .endpoint(AppRoute.onboarding)
//            ]),
//
//            // Tabbar
//            RoutingNode(lazyTabBarRoutePresenter(
//                optionsDescription: [
//                    (title: "Today",  icon: nil, request: .today),
//                    (title: "Books", icon: nil, request: .books),
//                    (title: "Profile",  icon: nil, request: .profile)
//                ],
//                router: router)).fork([
//
//                // Today nav stack
//                RoutingNode(lazyNavigationRoutePresenter()).stack([
//
//                    // Today
//                    RoutingNode(lazyPresenter(for: .today, router: router))
//                        .endpoint(AppRoute.today, children: [
//
//                        // All news
//                        RoutingNode(lazyPresenter(for: .allNews, router: router))
//                            .endpoint(AppRoute.allNews)
//
//                        ], modals: [
//
//                        // Story
//                        RoutingNode(lazyPresenter(for: .story, router: router))
//                            .endpoint(AppRoute.story)
//                    ])
//                ]),
//
//                // Books nav stack
//                RoutingNode(lazyNavigationRoutePresenter()).stack([
//
//                    // Books
//                    RoutingNode(lazyPresenter(for: .books, router: router))
//                        .endpoint(AppRoute.books, children: [
//
//                        // Book
//                        RoutingNode(lazyPresenter(for: .book, router: router))
//                            .endpoint(AppRoute.book)
//
//                        // Book categories
//    //                    RoutingNode(lazyMockPresenter(for: .booksCategory, routeDispatcher: dispatcher))
//    //                        .endpoint(AppRoute.booksCategory)
//                    ])
//                ]),
//
//                // Profile nav stack
//                RoutingNode(lazyNavigationRoutePresenter()).stack([
//
//                    // Profile
//                    RoutingNode(lazyPresenter(for: .profile, router: router))
//                        .endpoint(AppRoute.profile, modals: [
//
//                            // Tabbar
//                            RoutingNode(lazyTabBarRoutePresenter(
//                                optionsDescription: [
//                                    (title: "Orders",  icon: nil, request: .orders),
//                                    (title: "Delivery",  icon: nil, request: .deliveryInfo)
//                                ],
//                                router: router)).fork([
//
//                                    // Orders nav stack
//                                    RoutingNode(lazyNavigationRoutePresenter()).stack([
//
//                                        // Orders done
//                                        RoutingNode(lazyPresenter(for: .orders, router: router))
//                                            .endpoint(AppRoute.orders)
//                                    ]),
//
//                                    // Delivery info
//                                    RoutingNode(lazyPresenter(for: .deliveryInfo, router: router))
//                                        .endpoint(AppRoute.deliveryInfo)
//                            ])
//                    ])
//                ])
//            ])
//    ])
// }
