import SwiftUI
import UIKit

struct CarouselPageIndicator: UIViewRepresentable {
    let numberOfPages: Int
    let currentPage: Int

    func makeUIView(context: Context) -> UIPageControl {
        let pageControl = UIPageControl()
        pageControl.backgroundStyle = .minimal
        pageControl.hidesForSinglePage = true
        pageControl.allowsContinuousInteraction = false
        pageControl.isUserInteractionEnabled = false
        pageControl.isAccessibilityElement = false
        pageControl.currentPageIndicatorTintColor = .label.withAlphaComponent(0.72)
        pageControl.pageIndicatorTintColor = .secondaryLabel.withAlphaComponent(0.28)
        return pageControl
    }

    func updateUIView(_ pageControl: UIPageControl, context: Context) {
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = currentPage
    }
}
