import Foundation
import UIKit

// MARK: - Date Formatting

extension Date {
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}

// MARK: - Double Currency Formatting

extension Double {
    var eurFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle       = .currency
        formatter.currencyCode      = "EUR"
        formatter.currencySymbol    = "€"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "€\(self)"
    }
}

// MARK: - UIColor Helpers

extension UIColor {
    static var income:  UIColor { .systemGreen }
    static var expense: UIColor { .systemRed   }
}

// MARK: - UIView Shadows

extension UIView {
    func applyShadow(radius: CGFloat = 8, opacity: Float = 0.1, offset: CGSize = CGSize(width: 0, height: 4)) {
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowRadius  = radius
        layer.shadowOpacity = opacity
        layer.shadowOffset  = offset
    }
}
