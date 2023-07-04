//
//  ViewController.swift
//  AutoCarouselDemo
//
//  Created by feng qiu on 2023/6/24.
//

import UIKit

class AutoCarouselViewController: UIViewController {
    
    var dataSource: [UIImage] = []
    var originalDataSource: [UIImage] = []
    var carouselView: AutoCarouselView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        loadData()
        setupView()
        carouselView.reloadData()
    }
    
    func loadData() {
        for i in 0..<6 {
            if let cat = UIImage(named: "cat\(i+1)") {
                dataSource.append(cat)
            }
        }
    }
    
    func setupView() {
        carouselView = AutoCarouselView()
        carouselView.register(UIImageView.self, forCellReuseIdentifier: "carouselView.cell")
        carouselView.pageControl.pageIndicatorTintColor = .white.withAlphaComponent(0.3)
        carouselView.pageControl.currentPageIndicatorTintColor = .white
        carouselView.updateStyle { style in
            style.withInset(NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                .withDirection(.fromRight)
        }
        carouselView.delegate = self
        carouselView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(carouselView)
        NSLayoutConstraint.activate([
            carouselView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carouselView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carouselView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            carouselView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
}

extension AutoCarouselViewController: AutoCarouselViewDelegate {
    func numberOfCells() -> Int {
        return dataSource.count
    }
    
    func carouselView(_ carouselView: AutoCarouselView, cellForIndex index: Int) -> UIView? {
        let imageView: UIImageView? = carouselView.dequeueReusableCell(withIdentifier: "carouselView.cell", for: index) as? UIImageView
        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true
        imageView?.isUserInteractionEnabled = true
        imageView?.image = dataSource[index]
        return imageView
    }
    
    func carouselView(_ carouselView: AutoCarouselView, didSelectCell cell: UIView?, atIndex index: Int) {
        print("carouselView didSelectCell index \(index)")
    }
    
    func carouselView(_ carouselView: AutoCarouselView, delayForIndex index: Int) -> TimeInterval {
        return 3//TimeInterval(index + 1)
    }
}
