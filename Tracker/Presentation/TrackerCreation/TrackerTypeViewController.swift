import UIKit

final class TrackerTypeViewController: UIViewController {
    weak var delegate: NewTrackerViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        navigationItem.title = "Создание трекера"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal

        let habitButton = UIButton.trackerFilled(title: "Привычка")
        habitButton.addTarget(self, action: #selector(habitTapped), for: .touchUpInside)
        let eventButton = UIButton.trackerFilled(title: "Нерегулярное событие")
        eventButton.addTarget(self, action: #selector(eventTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [habitButton, eventButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.applyTrackerAppearance(usesCompactTitle: true)
    }

    @objc private func habitTapped() {
        openCreation(.habit)
    }

    @objc private func eventTapped() {
        openCreation(.irregularEvent)
    }

    private func openCreation(_ type: TrackerCreationType) {
        let viewController = NewTrackerViewController(type: type)
        viewController.delegate = delegate
        navigationController?.pushViewController(viewController, animated: true)
    }
}
