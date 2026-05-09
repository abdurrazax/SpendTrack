import UIKit
import Combine

// MARK: - TransactionListViewController

final class TransactionListViewController: UIViewController {

    // MARK: - ViewModel

    private let viewModel: TransactionListViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var summaryCard: SummaryCardView = {
        let view = SummaryCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseID)
        tv.delegate   = self
        tv.dataSource = self
        return tv
    }()

    private lazy var addButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No transactions yet.\nTap + to add one."
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init

    init(viewModel: TransactionListViewModel = TransactionListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        Task { await viewModel.loadTransactions() }
    }

    // MARK: - Setup

    private func setupUI() {
        title = "SpendTrack"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = addButton
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(summaryCard)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            summaryCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            summaryCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            summaryCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            summaryCard.heightAnchor.constraint(equalToConstant: 110),

            tableView.topAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
        ])
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                self?.tableView.reloadData()
                self?.emptyLabel.isHidden = !transactions.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$summary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summary in
                self?.summaryCard.configure(with: summary)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.showAlert(message: message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func didTapAdd() {
        let addVM = AddTransactionViewModel()
        let addVC = AddTransactionViewController(viewModel: addVM) { [weak self] transaction in
            Task { await self?.viewModel.addTransaction(transaction) }
        }
        let nav = UINavigationController(rootViewController: addVC)
        present(nav, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension TransactionListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseID, for: indexPath) as! TransactionCell
        cell.configure(with: viewModel.transactions[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Recent Transactions"
    }
}

// MARK: - UITableViewDelegate

extension TransactionListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 68 }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else { return }
            let id = self.viewModel.transactions[indexPath.row].id
            Task { await self.viewModel.deleteTransaction(id: id) }
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - TransactionCell

final class TransactionCell: UITableViewCell {
    static let reuseID = "TransactionCell"

    private let emojiLabel   = UILabel()
    private let titleLabel   = UILabel()
    private let dateLabel    = UILabel()
    private let amountLabel  = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        emojiLabel.font  = .systemFont(ofSize: 28)
        titleLabel.font  = .systemFont(ofSize: 15, weight: .semibold)
        dateLabel.font   = .systemFont(ofSize: 12)
        dateLabel.textColor = .secondaryLabel
        amountLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        amountLabel.textAlignment = .right

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let row = UIStackView(arrangedSubviews: [emojiLabel, textStack, amountLabel])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            row.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func configure(with transaction: Transaction) {
        emojiLabel.text  = transaction.category.emoji
        titleLabel.text  = transaction.title
        dateLabel.text   = transaction.date.formatted(date: .abbreviated, time: .omitted)
        let prefix       = transaction.type == .income ? "+" : "-"
        amountLabel.text = "\(prefix)€\(String(format: "%.2f", transaction.amount))"
        amountLabel.textColor = transaction.type == .income ? .systemGreen : .systemRed
    }
}
