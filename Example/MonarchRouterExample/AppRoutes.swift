//
//  AppRoutes.swift
//  MonarchRouterExample
//
//  Created by Eliah Snakin on 19.10.2019.
//  Copyright © 2019 nikans.com. All rights reserved.
//

import Foundation
import MonarchRouter

/// Your app routing requests
enum AppRoutingRequest: RoutingRequestType {
    case login
    case onboarding(name: String)
    case today
    case story(type: String, id: Int, title: String)
    case allNews
    case books
    case book(id: Int, title: String?)
    case booksCategory(id: Int)
    case profile
    case orders
    case deliveryInfo

    var request: String {
        switch self {
        case .login:
            return "login"

        case let .onboarding(name):
            return "onboarding?name=\(name)"

        case .today:
            return "today"

        case let .story(type, id, title):
            return "today/story/\(type)/\(id)?title=\(title)"

        case .allNews:
            return "all_news"

        case .books:
            return "books"

        case let .book(id, title):
            return "books/\(id)?title=\(title ?? "")"

        case let .booksCategory(id):
            return "books/categories/\(id)"

        case .profile:
            return "profile"

        case .orders:
            return "orders"

        case .deliveryInfo:
            return "delivery"
        }
    }

    func resolve(for route: RouteType) -> RoutingResolvedRequestType {
        return request.resolve(for: route)
    }
}

/// Your app custom Routes
enum AppRoute: String, RouteType {
    case login
    case onboarding
    case today
    case story = "today/story/:type/:id"
    case allNews = "all_news"
    case books
    case book = "books/:id"
    case booksCategory = "books/categories/:id"

    // Notice, that if you want to open a book from a books category scene, you would need to create a separate route i.e. "books/categories/:category_id/book/:book_id". It may seem more appropriate to just push a book info scene into the navigation stack.
    // Still, a separate route for a book info scene may be useful for deep-linking.

    case profile
    case orders
    case deliveryInfo = "delivery"

    var components: [RouteComponent] {
        return rawValue.components
    }
}

/// Describes the object capable of Routes switching.
protocol ProvidesRouteDispatch: AnyObject {
    /// Extension method to change the Route.
    /// - parameter request: `AppRoutingRequest` to navigate to.
    func dispatch(_ request: AppRoutingRequest)

    /// Extension method to change the Route.
    /// - parameter request: `AppRoutingRequest` to navigate to.
    /// - parameter options: Special options for navigation (see `DispatchRouteOption` enum).
    func dispatch(_ request: AppRoutingRequest, options: [DispatchRouteOption])
}

// Extending `RouterStore` to accept custom `AppRoutingRequest` in dispatch methods.
extension RouterStore: ProvidesRouteDispatch {
    func dispatch(_ request: AppRoutingRequest) {
        dispatch(request.request)
    }

    func dispatch(_ request: AppRoutingRequest, options: [DispatchRouteOption]) {
        dispatch(request.request, options: options)
    }
}
