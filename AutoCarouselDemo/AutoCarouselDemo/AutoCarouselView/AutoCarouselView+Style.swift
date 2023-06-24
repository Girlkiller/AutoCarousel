//
//  AutoCarouselView+Style.swift
//  FreeDesign
//
//  Created by feng qiu on 2023/6/23.
//

import UIKit

public enum AutoCarouselDirection {
    case fromLeft
    case fromRight
    case fromTop
    case fromBottom
}

public enum AutoCarouselAnimationOptions: CaseIterable {
    case linear
    case easeIn
    case easeOut
    case easeInEaseOut
    case `default`
    
    var timingFunction: CAMediaTimingFunction {
        switch self {
        case .linear:
            return CAMediaTimingFunction(name: .linear)
        case .easeIn:
            return CAMediaTimingFunction(name: .easeIn)
        case .easeOut:
            return CAMediaTimingFunction(name: .easeOut)
        case .easeInEaseOut:
            return CAMediaTimingFunction(name: .easeInEaseOut)
        default:
            return CAMediaTimingFunction(name: .default)
        }
    }
}

extension AutoCarouselView {
    public static var defaultAutoCarouselViewStyle: AutoCarouselView.Style {
        .init(defaults: defaultAutoCarouselStyleProperties)
    }
    
    private static var defaultAutoCarouselStyleProperties: AutoCarouselView.Style.DefaultProperties {
        .init(inset: .zero,
              direction: .fromRight,
              duration: 0.25,
              delay: 3.0,
              animationOption: .easeInEaseOut)
    }
    
    public struct Style {
        private let defaults: DefaultProperties
        private var overrides: ConfigurableProperties
        
        public func withInset(_ inset: NSDirectionalEdgeInsets) -> Style {
            var style = self
            style.overrides.inset = inset
            return style
        }
        
        public func withDirection(_ direction: AutoCarouselDirection) -> Style {
            var style = self
            style.overrides.direction = direction
            return style
        }

        public func withDuration(_ duration: CFTimeInterval) -> Style {
            var style = self
            style.overrides.duration = duration
            return style
        }
        
        public func withDelay(_ delay: CFTimeInterval) -> Style {
            var style = self
            style.overrides.delay = delay
            return style
        }
        
        public func withAnimationOption(_ option: AutoCarouselAnimationOptions) -> Style {
            var style = self
            style.overrides.animationOption = option
            return style
        }
        
        init(defaults: DefaultProperties) {
            self.defaults = defaults
            overrides = ConfigurableProperties(
                inset: defaults.inset,
                direction: defaults.direction,
                duration: defaults.duration,
                delay: defaults.delay,
                animationOption: defaults.animationOption)
        }
    }
}

extension AutoCarouselView.Style {
    var inset: NSDirectionalEdgeInsets { overrides.inset }
    var direction: AutoCarouselDirection { overrides.direction }
    var duration: CFTimeInterval { overrides.duration }
    var delay: CFTimeInterval { overrides.delay }
    var animationOption: AutoCarouselAnimationOptions { overrides.animationOption }
    
    struct DefaultProperties {
        let inset: NSDirectionalEdgeInsets
        let direction: AutoCarouselDirection
        let duration: CFTimeInterval
        let delay: CFTimeInterval
        let animationOption: AutoCarouselAnimationOptions
    }
    
    struct ConfigurableProperties {
        var inset: NSDirectionalEdgeInsets
        var direction: AutoCarouselDirection
        var duration: CFTimeInterval
        var delay: CFTimeInterval
        var animationOption: AutoCarouselAnimationOptions
    }
}
