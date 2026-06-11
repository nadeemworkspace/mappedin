//
//  RouteItem.swift
//  MappedInDemoApp
//
//  Created by muhammed.nadeem.m.a on 11/06/26.
//

import Foundation
import Mappedin

enum RouteItem {
    case mapObject(MapObject)
    case space(Space)

    var name: String {
        switch self {
        case .mapObject(let object):
            return object.name

        case .space(let space):
            return space.name
        }
    }
}
