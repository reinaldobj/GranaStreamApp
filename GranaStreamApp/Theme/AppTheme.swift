import SwiftUI

/// Typealias para compatibilidade - use DS diretamente em código novo
/// @available(*, deprecated, message: "Use DS namespace diretamente")
enum AppTheme {
    /// Use DS.Typography diretamente em código novo
    typealias Typography = DS.Typography
    
    /// Use DS.Spacing diretamente em código novo
    typealias Spacing = DS.Spacing
    
    /// Use DS.Radius diretamente em código novo
    typealias Radius = DS.Radius
    
    /// Use DS.Shadow diretamente em código novo
    typealias Shadow = DS.Shadow
}
