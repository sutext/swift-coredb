//
//  EntityMacro.swift
//  swift-coredb
//
//  Created by supertext on 2025/2/26.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

struct EntityError:Error,CustomStringConvertible{
    var message:String
    init(_ message: String) {
        self.message = message
    }
    var description: String{
        message
    }
}
@resultBuilder
struct EntityBuilder{
    static func buildBlock(_ components: String...) -> [String] {
        components
    }
    static func buildOptional(_ component: [String]?) -> [String] {
        component == nil ? [] : component!
    }
    
    static func buildEither(first component: [String]) -> [String] {
        component
    }
   
    static func buildArray(_ components: [[String]]) -> [String] {
        components.flatMap { cms in
            cms
        }
    }
}

struct EntityMacro: MemberMacro,MemberAttributeMacro,ExtensionMacro {
    
    static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let `struct` = declaration.as(StructDeclSyntax.self) else {
            throw EntityError("For now, @Model can only be applied to a struct")
        }
        print(`struct`)
        return []
    }
    static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        return []
    }
    //MemberAttributeMacro
    static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax, providingAttributesFor member: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AttributeSyntax] {
        return []
    }
    //ExtensionMacro
    static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax, providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        return []
    }
    
    
    
    
}
