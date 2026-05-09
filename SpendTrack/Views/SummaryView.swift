import UIKit

// MARK: - SummaryCardView

final class SummaryCardView: UIView {

    private let balanceLabel  = UILabel()
    private let incomeLabel   = UILabel()
    private let expenseLabel  = UILabel()
    private let titleLabel    = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor   = .systemBlue
        layer.cornerRadius = 16
        layer.masksToBounds = true

        titleLabel.text      = "This Month"
        titleLabel.font      = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.8)

        balanceLabel.font      = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        balanceLabel.textColor = .white
        balanceLabel.text      = "€0.00"

        incomeLabel.font      = .systemFont(ofSize: 13)
        incomeLabel.textColor = UIColor.white.withAlphaComponent(0.9)

        expenseLabel.font      = .systemFont(ofSize: 13)
        expenseLabel.textColor = UIColor.white.withAlphaComponent(0.9)

        let bottomRow = UIStackView(arrangedSubviews: [incomeLabel, expenseLabel])
        bottomRow.axis         = .horizontal
        bottomRow.distribution = .equalSpacing

        let stack = UIStackView(arrangedSubviews: [titleLabel, balanceLabel, bottomRow])
        stack.axis    = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    func configure(with summary: MonthlySummary) {
        let prefix = summary.balanceIsPositive ? "+" : ""
        balanceLabel.text  = "\(prefix)€\(String(format: "%.2f", summary.balance))"
        balanceLabel.textColor = summary.balanceIsPositive ? .white : UIColor(red: 1, green: 0.8, blue: 0.8, alpha: 1)
        incomeLabel.text   = "↑ €\(String(format: "%.2f", summary.totalIncome))"
        expenseLabel.text  = "↓ €\(String(format: "%.2f", summary.totalExpenses))"
    }
}

// MARK: - AddTransactionViewController

final class AddTransactionViewController: UIViewController {

    private let viewModel: AddTransactionViewModel
    private let onSave: (Transaction) -> Void

    private let titleField    = UITextField()
    private let amountField   = UITextField()
    private let typeSegment   = UISegmentedControl(items: ["Expense", "Income"])
    private let categoryPicker = UIPickerView()
    private let noteField     = UITextField()
    private let saveButton    = UIButton(type: .system)

    init(viewModel: AddTransactionViewModel, onSave: @escaping (Transaction) -> Void) {
        self.viewModel = viewModel
        self.onSave    = onSave
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Add Transaction"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))

        titleField.placeholder  = "Title (e.g. Coffee)"
        titleField.borderStyle  = .roundedRect
        amountField.placeholder = "Amount (e.g. 3.50)"
        amountField.borderStyle = .roundedRect
        amountField.keyboardType = .decimalPad
        noteField.placeholder   = "Note (optional)"
        noteField.borderStyle   = .roundedRect
        typeSegment.selectedSegmentIndex = 0

        categoryPicker.dataSource = self
        categoryPicker.delegate   = self

        saveButton.setTitle("Save Transaction", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 12
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        let labels: [UILabel] = ["Title", "Amount (€)", "Type", "Category", "Note"].map {
            let l = UILabel(); l.text = $0; l.font = .systemFont(ofSize: 13, weight: .medium)
            l.textColor = .secondaryLabel; return l
        }

        let stack = UIStackView(arrangedSubviews: [
            labels[0], titleField,
            labels[1], amountField,
            labels[2], typeSegment,
            labels[3], categoryPicker,
            labels[4], noteField,
            saveButton
        ])
        stack.axis    = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            categoryPicker.heightAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    @objc private func didTapCancel() { dismiss(animated: true) }

    @objc private func didTapSave() {
        viewModel.title       = titleField.text ?? ""
        viewModel.amountText  = amountField.text ?? ""
        viewModel.selectedType = typeSegment.selectedSegmentIndex == 0 ? .expense : .income
        viewModel.note        = noteField.text ?? ""

        guard let transaction = viewModel.buildTransaction() else {
            let alert = UIAlertController(title: "Invalid Input", message: viewModel.validationMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        onSave(transaction)
        dismiss(animated: true)
    }
}

// MARK: - UIPickerViewDataSource / Delegate

extension AddTransactionViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        Category.allCases.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let cat = Category.allCases[row]
        return "\(cat.emoji)  \(cat.rawValue)"
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.selectedCategory = Category.allCases[row]
    }
}
