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
        
        static let swipeVelocity: CGFloat = 500
    }
    
    private lazy var containerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.accessibilityIdentifier = AccessibilityIdentifiers.animationContainer
        return view
    }()
    
    public private(set) lazy var preAnimationView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.backgroundColor = .orange
        stackView.accessibilityIdentifier = AccessibilityIdentifiers.preAnimationView
        stackView.tag = 0
        return stackView
    }()
    
    public private(set) lazy var nextAnimationView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.backgroundColor = .green
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
    
    private var style: Style = AutoCarouselView.defaultAutoCarouselViewStyle {
        didSet {
            applyStyling()
        }
    }
    
    private var timer: Timer?
    private var isReversed = false
    
    public var isInfinited = true
    public weak var delegate: AutoCarouselViewDelegate?
    
    private var cellNumber: Int {
        return delegate?.numberOfCells() ?? 0
    }
    
    private var index: Int = 0
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
    
    public override init(frame: CGRect) {
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
        NSLayoutConstraint.activate([
            preAnimationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            preAnimationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            preAnimationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            preAnimationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            nextAnimationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            nextAnimationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            nextAnimationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            nextAnimationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pageControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            pageControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func addGestures() {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(clickAction(tapGR:)))
        containerView.addGestureRecognizer(tapGR)
        let directions: [UISwipeGestureRecognizer.Direction] = [.right, .left, .up, .down]
        directions.forEach {
            addSwipeGesture(with: $0)
        }
    }
    
    func addSwipeGesture(with direction: UISwipeGestureRecognizer.Direction) {
        let swiper = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swiper.direction = direction
        swiper.numberOfTouchesRequired = 1
        containerView.addGestureRecognizer(swiper)
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
    }
    
    private func applyTransitionDirection(_ direction: AutoCarouselDirection) {
        switch direction {
        case .fromLeft:
            transition.subtype = .fromLeft
        case .fromRight:
            transition.subtype = .fromRight
        case .fromTop:
            transition.subtype = .fromTop
        case .fromBottom:
            transition.subtype = .fromBottom
        }
    }
}

// MARK: Gesture Handler
extension AutoCarouselView {
    @objc
    func handleSwipeGesture(_ swiper: UISwipeGestureRecognizer) {
        switch swiper.direction {
        case .down:
            if direction == .fromBottom || direction == .fromTop {
                startAnimation(.fromTop, shouldRestart: true)
            }
        case .up:
            if direction == .fromBottom || direction == .fromTop {
                startAnimation(.fromBottom, shouldRestart: true)
            }
        case .left:
            if direction == .fromLeft || direction == .fromRight {
                startAnimation(.fromRight, shouldRestart: true)
            }
        case .right:
            if direction == .fromLeft || direction == .fromRight {
                startAnimation(.fromLeft, shouldRestart: true)
            }
        default:
            break
        }
    }
    
    @objc
    func clickAction(tapGR: UITapGestureRecognizer) {
        let touchPoint = tapGR.location(in: containerView)
        if preAnimationView.layer.presentation()?.hitTest(touchPoint) != nil {
            delegate?.carouselView(self, didSelectCell: preAnimationView.arrangedSubviews.first, atIndex: preAnimationView.tag)
            print("didSelectCell index = \(preAnimationView.tag)")
            return
        }
        if nextAnimationView.layer.presentation()?.hitTest(touchPoint) != nil {
            delegate?.carouselView(self, didSelectCell: nextAnimationView.arrangedSubviews.first, atIndex: nextAnimationView.tag)
            print("didSelectCell index = \(nextAnimationView.tag)")
        }
    }
}

// MARK: Timer
extension AutoCarouselView {
    func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: style.delay, repeats: true) { [weak self] _ in
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
        containerView.gestureRecognizers?.forEach { $0.isEnabled = false }
        applyTransitionDirection(direction)
        prepareContent(for: direction)
        let size = containerView.bounds.size
        if isReversed {
            preAnimationView.frame = CGRect(origin: nextTransitionFromPoint(for: direction), size: size)
            nextAnimationView.frame = CGRect(origin: .zero, size: size)
        } else {
            preAnimationView.frame = CGRect(origin: .zero, size: size)
            nextAnimationView.frame = CGRect(origin: nextTransitionFromPoint(for: direction), size: size)
        }
        CATransaction.setCompletionBlock { [weak self] in
            self?.containerView.gestureRecognizers?.forEach { $0.isEnabled = true }
            guard let self = self, self.isInfinited, shouldRestart else { return }
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
        print("------- curent index = \(index)")
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
