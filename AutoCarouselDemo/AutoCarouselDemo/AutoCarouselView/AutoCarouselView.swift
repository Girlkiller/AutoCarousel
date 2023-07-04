//
//  AutoCarouselView.swift
//  FreeDesign
//
//  Created by feng qiu on 2023/6/23.
//

import UIKit
import Foundation

public class AutoCarouselView: UIStackView {
    private enum AccessibilityIdentifiers {
        static let animationContainer = "animation-container"
        static let preAnimationView = "pre-animation-view"
        static let nextAnimationView = "next-animation-view"
    }
    
    private enum Constants {
        static let animationNameKey = "animationName"
        static let preAnimationName = "preAnimationView.position"
        static let nextAnimationName = "nextAnimationView.position"
        
        static let swipeVelocity: CGFloat = 200
    }
    
    private lazy var containerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.accessibilityIdentifier = AccessibilityIdentifiers.animationContainer
        view.clipsToBounds = true
        return view
    }()
    
    public private(set) lazy var preAnimationView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        stackView.accessibilityIdentifier = AccessibilityIdentifiers.preAnimationView
        stackView.tag = 0
        return stackView
    }()
    
    public private(set) lazy var nextAnimationView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        stackView.accessibilityIdentifier = AccessibilityIdentifiers.nextAnimationView
        stackView.tag = 1
        return stackView
    }()
    
    public private(set) lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.hidesForSinglePage = true
        return pageControl
    }()

    private lazy var transition: CATransition = {
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromRight
        transition.isRemovedOnCompletion = false
        transition.fillMode = .both
        transition.duration = style.duration
        transition.timingFunction = style.animationOption.timingFunction
        return transition
    }()
    
    public private(set) var direction: AutoCarouselDirection = .fromRight {
        didSet {
            applyTransitionDirection(direction)
        }
    }
    
    public private(set) var style: Style = AutoCarouselView.defaultAutoCarouselViewStyle {
        didSet {
            applyStyling()
        }
    }
    
    private var delay: TimeInterval
    
    private var timer: Timer?
    private var isReversed = false
    
    public var isInfinited = true
    public weak var delegate: AutoCarouselViewDelegate?
    
    private var cellNumber: Int {
        return delegate?.numberOfCells() ?? 0
    }
    
    public private(set) var index: Int = 0
    private var preIndex: Int {
        var computedIndex = index - 1
        if computedIndex < 0 {
            computedIndex = cellNumber - 1
        }
        return computedIndex
    }
    
    private var nextIndex: Int {
        var computedIndex = index + 1
        if computedIndex >= cellNumber {
            computedIndex = 0
        }
        return computedIndex
    }
    
    private var isInitialized = false
    private var reusableCells: [String: [UIView]] = [:]
    private var typeMap: [String: UIView.Type] = [:]
    private var startPoint: CGPoint?
    private var currentView: UIView?
    private var startDirection: AutoCarouselDirection?
    
    public override init(frame: CGRect) {
        delay = style.delay
        super.init(frame: frame)
        setupViews()
        addGestures()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateStyle(_ closure: ((_ style: Style) -> Style)) {
        style = closure(style)
    }
    
    public func register(_ cellClass: UIView.Type, forCellReuseIdentifier identifier: String) {
        typeMap[identifier] = cellClass
    }
    
    public func dequeueReusableCell(withIdentifier identifer: String, for index: Int) -> UIView? {
        guard let cellClass = typeMap[identifer] else { return nil }
        var items = reusableCells[identifer] ?? []
        if items.isEmpty == true {
            return makeReusableCell()
        }
        let spareItems = items.filter {
            $0.superview?.center != preAnimationView.center && $0.superview?.center != nextAnimationView.center
        }
        if !spareItems.isEmpty {
            return spareItems.first
        } else {
            return makeReusableCell()
        }
        
        func makeReusableCell() -> UIView {
            let cell = cellClass.init()
            items.append(cell)
            reusableCells[identifer] = items
            return cell
        }
    }
    
    private func setupViews() {
        distribution = .fill
        addArrangedSubview(containerView)
        containerView.addSubview(nextAnimationView)
        containerView.addSubview(preAnimationView)
        containerView.addSubview(pageControl)
        
        switch direction {
        case .fromLeft:
            NSLayoutConstraint.activate([
                nextAnimationView.trailingAnchor.constraint(equalTo: containerView.leadingAnchor),
                nextAnimationView.topAnchor.constraint(equalTo: containerView.topAnchor),
                nextAnimationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        case .fromRight:
            NSLayoutConstraint.activate([
                nextAnimationView.leadingAnchor.constraint(equalTo: containerView.trailingAnchor),
                nextAnimationView.topAnchor.constraint(equalTo: containerView.topAnchor),
                nextAnimationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
        case .fromTop:
            NSLayoutConstraint.activate([
                nextAnimationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                nextAnimationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                nextAnimationView.bottomAnchor.constraint(equalTo: containerView.topAnchor)
            ])
        case .fromBottom:
            NSLayoutConstraint.activate([
                nextAnimationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                nextAnimationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                nextAnimationView.topAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        NSLayoutConstraint.activate([
            preAnimationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            preAnimationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            preAnimationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            preAnimationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            nextAnimationView.widthAnchor.constraint(equalTo: preAnimationView.widthAnchor),
            nextAnimationView.heightAnchor.constraint(equalTo: preAnimationView.heightAnchor),
            pageControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            pageControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func addGestures() {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(clickAction(tapGR:)))
        tapGR.delegate = self
        containerView.addGestureRecognizer(tapGR)
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(panAction(panGR:)))
        panGR.delegate = self
        containerView.addGestureRecognizer(panGR)
    }

    private func applyStyling() {
        if style.inset != .zero {
            isLayoutMarginsRelativeArrangement = true
            directionalLayoutMargins = style.inset
        } else {
            isLayoutMarginsRelativeArrangement = false
        }
        direction = style.direction
        transition.duration = style.duration
        transition.timingFunction = style.animationOption.timingFunction
        delay = style.delay
    }
    
    private func applyTransitionDirection(_ direction: AutoCarouselDirection) {
        switch direction {
        case .fromLeft:
            transition.subtype = .fromLeft
        case .fromRight:
            transition.subtype = .fromRight
        case .fromTop:
            transition.subtype = .fromBottom
        case .fromBottom:
            transition.subtype = .fromTop
        }
    }
}

// MARK: Gesture Handler
extension AutoCarouselView {
    @objc
    func clickAction(tapGR: UITapGestureRecognizer) {
        let touchPoint = tapGR.location(in: containerView)
        if preAnimationView.layer.presentation()?.hitTest(touchPoint) != nil {
            delegate?.carouselView(self, didSelectCell: preAnimationView.arrangedSubviews.first, atIndex: preAnimationView.tag)
            return
        }
        if nextAnimationView.layer.presentation()?.hitTest(touchPoint) != nil {
            delegate?.carouselView(self, didSelectCell: nextAnimationView.arrangedSubviews.first, atIndex: nextAnimationView.tag)
        }
    }
    
    @objc
    func panAction(panGR: UIPanGestureRecognizer) {
        let isHorizontalDirection = direction == .fromLeft || direction == .fromRight
        switch panGR.state {
        case .began:
            stopTimer()
            let direction: AutoCarouselDirection
            if isHorizontalDirection {
                let velocity = panGR.velocity(in: containerView).x
                direction = velocity > 0 ? .fromLeft : .fromRight
            } else {
                let velocity = panGR.velocity(in: containerView).y
                direction = velocity > 0 ? .fromTop : .fromBottom
            }
            prepareContent(for: direction)
            currentView = containerView.subviews.first(where: { $0.frame.origin == .zero && $0 is UIStackView })
            startPoint = nextTransitionFromPoint(for: direction)
            startDirection = direction
        case .changed:
            if isHorizontalDirection {
                handleHorizontalChangedAction(panGR)
            } else {
                handleVerticalChangedAction(panGR)
            }
        case .cancelled:
            handlePanAction(panGR)
        case .ended:
            handlePanAction(panGR)
        default:
            break
        }
    }
    
    private func handlePanAction(_ panGR: UIPanGestureRecognizer) {
        let isHorizontalDirection = direction == .fromLeft || direction == .fromRight
        if isHorizontalDirection {
            handleHorizontalPan(panGR)
        } else {
            handleVerticalPan(panGR)
        }
    }
    
    private func handleHorizontalPan(_ panGR: UIPanGestureRecognizer) {
        let velocity = panGR.velocity(in: containerView).x
        let translation = panGR.translation(in: containerView).x
        let size = containerView.bounds.size
        if abs(velocity) >= Constants.swipeVelocity {
            let direction: AutoCarouselDirection = velocity > 0 ? .fromLeft : .fromRight
            startAnimation(direction, shouldRestart: true)
        } else if abs(translation) >= size.width/2 {
            let direction: AutoCarouselDirection = translation > 0 ? .fromLeft : .fromRight
            startNormalAnimation(direction)
        } else {
            recoverHorizontalLocation()
        }
        panGR.setTranslation(.zero, in: containerView)
    }
    
    private func handleVerticalPan(_ panGR: UIPanGestureRecognizer) {
        let velocity = panGR.velocity(in: containerView).y
        let translation = panGR.translation(in: containerView).y
        let size = containerView.bounds.size
        if abs(velocity) >= Constants.swipeVelocity {
            let direction: AutoCarouselDirection = velocity > 0 ? .fromTop : .fromBottom
            startAnimation(direction, shouldRestart: true)
        } else if abs(translation) >= size.height/2 {
            let direction: AutoCarouselDirection = translation > 0 ? .fromTop : .fromBottom
            startNormalAnimation(direction)
        } else {
            recoverVerticalLocation()
        }
        panGR.setTranslation(.zero, in: containerView)
    }
    
    private func handleHorizontalChangedAction(_ panGR: UIPanGestureRecognizer) {
        let velocity = panGR.velocity(in: containerView).x
        let movingDirection: AutoCarouselDirection = velocity > 0 ? .fromLeft : .fromRight
        let width = containerView.bounds.size.width
        let isExceedBounds = preAnimationView.frame.minX < -width || preAnimationView.frame.minX > width ||
                             nextAnimationView.frame.minX < -width || nextAnimationView.frame.minX > width
        let size = containerView.bounds.size
        if movingDirection != startDirection, isExceedBounds {
            prepareContent(for: movingDirection)
            startPoint = nextTransitionFromPoint(for: movingDirection)
            startDirection = movingDirection
        }
        guard abs(velocity) > 0,
              let startPoint = startPoint,
              let currentView = currentView else {
                  return
              }
        let translation = panGR.translation(in: containerView).x
        if currentView == preAnimationView {
            preAnimationView.frame = CGRect(origin: CGPoint(x: translation, y: 0), size: size)
            nextAnimationView.frame = CGRect(origin: CGPoint(x: startPoint.x + translation, y: 0), size: size)
        } else {
            nextAnimationView.frame = CGRect(origin: CGPoint(x: translation, y: 0), size: size)
            preAnimationView.frame = CGRect(origin: CGPoint(x: startPoint.x + translation, y: 0), size: size)
        }
        if abs(translation) >= size.width/2 {
            panGR.isEnabled = false
            panGR.isEnabled = true
        }
    }
    
    private func handleVerticalChangedAction(_ panGR: UIPanGestureRecognizer) {
        let velocity = panGR.velocity(in: containerView).y
        let movingDirection: AutoCarouselDirection = velocity > 0 ? .fromTop : .fromBottom
        let height = containerView.bounds.size.height
        let isExceedBounds = preAnimationView.frame.minY < -height || preAnimationView.frame.minY > height ||
                             nextAnimationView.frame.minY < -height || nextAnimationView.frame.minY > height
        let size = containerView.bounds.size
        if movingDirection != startDirection, isExceedBounds {
            prepareContent(for: movingDirection)
            startPoint = nextTransitionFromPoint(for: movingDirection)
            startDirection = movingDirection
        }
        guard abs(velocity) > 0,
              let startPoint = startPoint,
              let currentView = currentView else {
                  return
              }
        let translation = panGR.translation(in: containerView).y
        if currentView == preAnimationView {
            preAnimationView.frame = CGRect(origin: CGPoint(x: 0, y: translation), size: size)
            nextAnimationView.frame = CGRect(origin: CGPoint(x: 0, y: startPoint.y + translation), size: size)
        } else {
            nextAnimationView.frame = CGRect(origin: CGPoint(x: 0, y: translation), size: size)
            preAnimationView.frame = CGRect(origin: CGPoint(x: 0, y: startPoint.y + translation), size: size)
        }
        if abs(translation) >= size.height/2 {
            panGR.isEnabled = false
            panGR.isEnabled = true
        }
    }
    
    private func recoverHorizontalLocation() {
        guard let currentView = currentView else {
            startPoint = nil
            currentView = nil
            startDirection = nil
            return
        }
        let size = containerView.bounds.size
        let isPreAnimationView = currentView == preAnimationView
        UIView.animate(withDuration: style.duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 10) {
            if isPreAnimationView {
                self.preAnimationView.frame = CGRect(origin: .zero, size: size)
                let isNextAtLeft = self.preAnimationView.frame.minX > self.nextAnimationView.frame.minX
                if isNextAtLeft {
                    self.nextAnimationView.frame = CGRect(origin: CGPoint(x: -size.width, y: 0), size: size)
                } else {
                    self.nextAnimationView.frame = CGRect(origin: CGPoint(x: size.width, y: 0), size: size)
                }
            } else {
                self.nextAnimationView.frame = CGRect(origin: .zero, size: size)
                let isPreAtLeft = self.nextAnimationView.frame.minX > self.preAnimationView.frame.minX
                if isPreAtLeft {
                    self.preAnimationView.frame = CGRect(origin: CGPoint(x: -size.width, y: 0), size: size)
                } else {
                    self.preAnimationView.frame = CGRect(origin: CGPoint(x: size.width, y: 0), size: size)
                }
            }
        } completion: { _ in
            self.startPoint = nil
            self.currentView = nil
            self.startDirection = nil
            if self.isInfinited {
                self.startTimer()
            }
        }
    }
    
    private func startNormalAnimation(_ direction: AutoCarouselDirection) {
        var delay = delay
        let size = containerView.bounds.size
        UIView.animate(withDuration: style.duration, delay: 0) {
            if self.isReversed {
                self.preAnimationView.frame = CGRect(origin: .zero, size: size)
                self.nextAnimationView.frame = CGRect(origin: self.preTransitionToPoint(for: direction), size: size)
            } else {
                self.preAnimationView.frame = CGRect(origin: self.preTransitionToPoint(for: direction), size: size)
                self.nextAnimationView.frame = CGRect(origin: .zero, size: size)
            }
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.startPoint = nil
            self.currentView = nil
            self.startDirection = nil
            self.containerView.gestureRecognizers?.forEach { $0.isEnabled = true }
            self.style = self.style.withDelay(delay)
            guard self.isInfinited else { return }
            self.startTimer()
        }
        isReversed = !isReversed
        updateIndex(with: direction)
        pageControl.currentPage = index
        delay = delegate?.carouselView(self, delayForIndex: index) ?? delay
        print("\(Date())------- curent index = \(index)")
    }
    
    private func recoverVerticalLocation() {
        guard let currentView = currentView else {
            startPoint = nil
            currentView = nil
            return
        }
        let size = containerView.bounds.size
        let isPreAnimationView = currentView == preAnimationView
        UIView.animate(withDuration: style.duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 10) {
            if isPreAnimationView {
                self.preAnimationView.frame = CGRect(origin: .zero, size: size)
                let isNextAtTop = self.preAnimationView.frame.minY > self.nextAnimationView.frame.minY
                if isNextAtTop {
                    self.nextAnimationView.frame = CGRect(origin: CGPoint(x: 0, y: -size.height), size: size)
                } else {
                    self.nextAnimationView.frame = CGRect(origin: CGPoint(x: 0, y: size.height), size: size)
                }
            } else {
                self.nextAnimationView.frame = CGRect(origin: .zero, size: size)
                let isPreAtTop = self.nextAnimationView.frame.minY > self.preAnimationView.frame.minY
                if isPreAtTop {
                    self.preAnimationView.frame = CGRect(origin: CGPoint(x: 0, y: -size.height), size: size)
                } else {
                    self.preAnimationView.frame = CGRect(origin: CGPoint(x: 0, y: size.height), size: size)
                }
            }
        } completion: { _ in
            self.startPoint = nil
            self.currentView = nil
            if self.isInfinited {
                self.startTimer()
            }
        }
    }
}

// MARK: Timer
extension AutoCarouselView {
    func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: delay, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.startAnimation(self.direction)
        }
        RunLoop.current.add(timer, forMode: .common)
        if !Thread.isMainThread {
            RunLoop.current.run()
        }
        self.timer = timer
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: DataSource
extension AutoCarouselView {
    public func reloadData() {
        let numberOfPages = cellNumber
        isReversed = false
        isInitialized = false
        pageControl.numberOfPages = numberOfPages
        pageControl.isHidden = true
        prepareInitialContent()
        startTimer()
    }
    
    func updateIndex(with direction: AutoCarouselDirection) {
        if direction == self.direction {
            if index < cellNumber - 1 {
                index += 1
            } else {
                index = 0
            }
        } else if isOppositeDirection(direction) {
            if index > 0 {
                index -= 1
            } else {
                index = cellNumber - 1
            }
        }
    }
    
    func isOppositeDirection(_ direction: AutoCarouselDirection) -> Bool {
        switch (direction, self.direction) {
        case (.fromLeft, .fromRight):
            return true
        case (.fromRight, .fromLeft):
            return true
        case (.fromTop, .fromBottom):
            return true
        case (.fromBottom, .fromTop):
            return true
        default:
            return false
        }
    }
    
    func prepareContent(for direction: AutoCarouselDirection) {
        guard let delegate = delegate else {
            return
        }
        guard isInitialized else {
            prepareInitialContent()
            return
        }
        let isOpposite = isOppositeDirection(direction)
        let nextIndex = isOpposite ? preIndex : nextIndex
        print("nextIndex = \(nextIndex)")
        guard let nextContent = delegate.carouselView(self, cellForIndex: nextIndex) else {
            return
        }
        if !isReversed {
            clearNextContent()
            nextAnimationView.addArrangedSubview(nextContent)
            nextAnimationView.tag = nextIndex
        } else {
            clearPreContent()
            preAnimationView.addArrangedSubview(nextContent)
            preAnimationView.tag = nextIndex
        }
    }
    
    func prepareInitialContent() {
        guard let delegate = delegate, !isInitialized else {
            return
        }
        isInitialized = true
        if let preContent = delegate.carouselView(self, cellForIndex: index) {
            clearPreContent()
            preAnimationView.addArrangedSubview(preContent)
            preAnimationView.tag = index
        }
        if let nextContent = delegate.carouselView(self, cellForIndex: nextIndex) {
            clearNextContent()
            nextAnimationView.addArrangedSubview(nextContent)
            nextAnimationView.tag = nextIndex
        }
        pageControl.currentPage = index
    }
    
    func clearContent() {
        clearPreContent()
        clearNextContent()
    }
    
    func clearPreContent() {
        preAnimationView.arrangedSubviews.forEach {
            preAnimationView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    func clearNextContent() {
        nextAnimationView.arrangedSubviews.forEach {
            nextAnimationView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
}

extension AutoCarouselView {
    public func startAnimation(_ direction: AutoCarouselDirection, shouldRestart: Bool = false) {
        var delay = delay
        containerView.gestureRecognizers?.forEach {
            if $0 is UIPanGestureRecognizer {
                $0.isEnabled = false
            }
        }
        applyTransitionDirection(direction)
        let isMoving = startPoint != nil
        if isMoving == false {
            prepareContent(for: direction)
        }
        let size = containerView.bounds.size
        if isReversed {
            preAnimationView.frame = isMoving ? preAnimationView.frame : CGRect(origin: nextTransitionFromPoint(for: direction), size: size)
            nextAnimationView.frame = isMoving ? nextAnimationView.frame : CGRect(origin: .zero, size: size)
        } else {
            preAnimationView.frame = isMoving ? preAnimationView.frame : CGRect(origin: .zero, size: size)
            nextAnimationView.frame = isMoving ? nextAnimationView.frame : CGRect(origin: nextTransitionFromPoint(for: direction), size: size)
        }
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self else { return }
            self.startPoint = nil
            self.currentView = nil
            self.startDirection = nil
            self.containerView.gestureRecognizers?.forEach { $0.isEnabled = true }
            let shouldRestart = shouldRestart || delay != self.delay
            self.style = self.style.withDelay(delay)
            guard self.isInfinited, shouldRestart else { return }
            self.startTimer()
        }
        preAnimationView.layer.add(transition, forKey: nil)
        nextAnimationView.layer.add(transition, forKey: nil)
        if isReversed {
            preAnimationView.frame = CGRect(origin: .zero, size: size)
            nextAnimationView.frame = CGRect(origin: preTransitionToPoint(for: direction), size: size)
        } else {
            preAnimationView.frame = CGRect(origin: preTransitionToPoint(for: direction), size: size)
            nextAnimationView.frame = CGRect(origin: .zero, size: size)
        }
        isReversed = !isReversed
        updateIndex(with: direction)
        pageControl.currentPage = index
        delay = delegate?.carouselView(self, delayForIndex: index) ?? delay
        print("\(Date())------- curent index = \(index)")
    }

    private func preTransitionToPoint(for direction: AutoCarouselDirection) -> CGPoint {
        let width = bounds.width
        let height = bounds.height
        let point: CGPoint
        switch direction {
        case .fromLeft:
            point = CGPoint(x: width, y: 0)
        case .fromRight:
            point = CGPoint(x: -width, y: 0)
        case .fromTop:
            point = CGPoint(x: 0, y: height)
        case .fromBottom:
            point = CGPoint(x: 0, y: -height)
        }
        return point
    }
    
    private func nextTransitionFromPoint(for direction: AutoCarouselDirection) -> CGPoint {
        let width = bounds.width
        let height = bounds.height
        let point: CGPoint
        switch direction {
        case .fromLeft:
            point = CGPoint(x: -width, y: 0)
        case .fromRight:
            point = CGPoint(x: width, y: 0)
        case .fromTop:
            point = CGPoint(x: 0, y: -height)
        case .fromBottom:
            point = CGPoint(x: 0, y: height)
        }
        return point
    }
}

extension AutoCarouselView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if containerView.gestureRecognizers?.contains(gestureRecognizer) == true {
            return true
        }
        return false
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
