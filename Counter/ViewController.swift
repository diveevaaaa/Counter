import UIKit

class ViewController: UIViewController {
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var counterButton: UIButton!

    private var counter = 0

    @IBAction private func counterButtonTapped(_ sender: UIButton) {
        counter += 1
        updateCounterLabel()
    }

    private func updateCounterLabel() {
        counterLabel.text = "Значение счётчика: \(counter)"
    }
}
