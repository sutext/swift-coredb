//
//  CoredbPlugin.swift
//  swift-coredb
//
//  Created by supertext on 2025/2/26.
//

#if canImport(SwiftCompilerPlugin)

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CoredbPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [

        // MARK: Environment
        EntityMacro.self

    ]
}

#endif
