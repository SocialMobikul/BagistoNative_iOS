import UIKit

final class MLImageSearchViewController: UIViewController {

    // MARK: - Public
    var searchType: MLSearchType = .image
    var callBack: ((String) -> Void)?

    // MARK: - ViewModel
    private let viewModel = MLImageSearchViewModel()

    // MARK: - UI
    let closeBtn = UIButton(type: .system)
    let suggestionView = UIView()
    let suggestionLabel = UILabel()
    let arrowImageView = UIImageView()
    let stackView = UIStackView()
    let tableView = UITableView()

    private var suggestionViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewModel()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Close Button
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // Suggestion Label
        suggestionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        suggestionLabel.text = "0 Suggestions"

        // Arrow (optional)
        arrowImageView.image = UIImage(systemName: "chevron.up")
        arrowImageView.tintColor = .gray

        // StackView
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.addArrangedSubview(suggestionLabel)

        // Suggestion View
        suggestionView.backgroundColor = .secondarySystemBackground
        suggestionView.layer.cornerRadius = 12

        [closeBtn, tableView, suggestionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        stackView.translatesAutoresizingMaskIntoConstraints = false
        suggestionView.addSubview(stackView)

        suggestionViewHeightConstraint = suggestionView.heightAnchor.constraint(equalToConstant: 40)

        NSLayoutConstraint.activate([
            // Close Button (top-right)
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Suggestion View (bottom)
            suggestionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            suggestionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            suggestionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            suggestionViewHeightConstraint,

            // Table View (BOTTOM HALF)
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: suggestionView.topAnchor, constant: -8),
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),

            // StackView inside Suggestion View
            stackView.topAnchor.constraint(equalTo: suggestionView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: suggestionView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: suggestionView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: suggestionView.bottomAnchor, constant: -12)
        ])
    }

    private func setupViewModel() {
        viewModel.controller = self
        viewModel.delegate = self
        viewModel.prepareView()
        viewModel.startImageLabeling()
    }

    // MARK: - Helpers
    func expandSuggestionView(height: CGFloat) {
        suggestionViewHeightConstraint.constant = height
        UIView.animate(withDuration: 0.3) {
            self.suggestionView.layer.cornerRadius = 0
            self.view.layoutIfNeeded()
        }
    }

    func collapseSuggestionView() {
        suggestionViewHeightConstraint.constant = 40
        UIView.animate(withDuration: 0.3) {
            self.suggestionView.layer.cornerRadius = 12
            self.view.layoutIfNeeded()
        }
    }

    func updateSuggestionCount(_ count: Int) {
        suggestionLabel.text = "\(count) Suggestions"
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Delegate
extension MLImageSearchViewController: MLSearchDelegate {
    func onSelected(data selected: String) {
        viewModel.stopImageLabeling()
        dismiss(animated: true) {
            self.callBack?(selected)
        }
    }
}

enum MLSearchType {
    case image
    case text
}
