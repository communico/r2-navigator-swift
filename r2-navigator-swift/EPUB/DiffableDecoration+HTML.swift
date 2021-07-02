//
//  Copyright 2021 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import R2Shared

extension Array where Element == DecorationChange {
    func javascript(forGroup group: String, styles: [Decoration.Style: HTMLDecorationStyle]) -> String? {
        guard !isEmpty else {
            return nil
        }

        return
            """
            // Using requestAnimationFrame helps to make sure the page is fully laid out before adding the
            // decorations.
            requestAnimationFrame(function () {
                let group = readium.getDecorations('\(group)');
                \(compactMap { $0.javascript(styles: styles) }.joined(separator: "\n"))
            });
            """
    }
}

extension DecorationChange {
    func javascript(styles: [Decoration.Style: HTMLDecorationStyle]) -> String? {
        func serializeJSON(of decoration: Decoration) -> String? {
            guard let style = styles[decoration.style] else {
                EPUBNavigatorViewController.log(.error, "Decoration style not registered: \(decoration.style.rawValue)")
                return nil
            }
            var json = decoration.json
            json["element"] = style.makeElement(decoration)
            guard let jsonString = serializeJSONString(json) else {
                EPUBNavigatorViewController.log(.error, "Can't serialize decoration to JSON: \(json)")
                return nil
            }
            return jsonString
        }

        switch self {
        case .add(let decoration):
            return serializeJSON(of: decoration)
                .map { "group.add(\($0));" }
        case .remove(let identifier):
            return "group.remove('\(identifier)');"
        case .update(let decoration):
            return serializeJSON(of: decoration)
                .map { "group.update(\($0));" }
        }
    }
}
