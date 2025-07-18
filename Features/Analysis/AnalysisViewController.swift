//
//  AnalysisViewController.swift
//  MoneyDetector
//
//  Экран «Анализ» с сетевой загрузкой и исходным визуальным дизайном.
//

import UIKit

/// Экран «Анализ». Твой исходный дизайн сохранён, добавлены сетевые загрузки
/// (BankAccountServise / CotegoriesServise / TransactionServise).
///
/// Что делает:
///  - Период: дата начала / конца с выбором через popover-календарь.
///  - Сумма: сумма всех транзакций в выбранном периоде (как в твоём исходнике).
///  - Сегмент «Дата / Сумма»: локальная сортировка отображаемого списка.
///  - Таблица операций: каждая строка = транзакция, категории берутся из сервиса.
///  - Оверлей загрузки/ошибок реализован через activity + errorLabel.
///
/// Использование:
///   let vc = AnalysisViewController()
///   present(vc, animated: true)
final class AnalysisViewController: UIViewController {

    // MARK: - UI
    private let backButton    = UIButton(type: .system)
    private let titleLabel    = UILabel()
    private let filterCard    = UIView()
    private let filterStack   = UIStackView()
    private let periodFromRow = UIStackView()
    private let periodToRow   = UIStackView()
    private let periodFromLabel = UILabel()
    private let periodToLabel   = UILabel()
    private let periodFromValue = PaddedLabel()
    private let periodToValue   = PaddedLabel()
    private let sumRow          = UIStackView()
    private let sumTitleLabel   = UILabel()
    private let sumValueLabel   = UILabel()
    private let sortControl     = UISegmentedControl(items: ["Дата", "Сумма"])
    private let sectionLabel    = UILabel()
    private let tableView       = UITableView()
    private let activity        = UIActivityIndicatorView(style: .medium)
    private let errorLabel      = UILabel()

    // MARK: - Services (network)
    private let accountService    = BankAccountServise.shared
    private let categoriesService = CotegoriesServise.shared
    private let txService         = TransactionServise.shared

    // MARK: - Data
    private var transactions: [Transaction] = []
    private var categories:   [Int: Category] = [:]
    private var sortKind: SortKind = .date
    private var dateFrom = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    private var dateTo   = Date()
    private var totalSum: Decimal = 0

    enum SortKind { case date, amount }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        setupUI()
        setupGestures()
        applyPeriodLabels()
        loadCategories()  // подтянем категории
        reloadData()      // первая загрузка транзакций
    }

    // MARK: - UI SETUP (твой дизайн)
    private func setupUI() {
        // BACK
        let backStack = UIStackView()
        backStack.axis = .horizontal
        backStack.spacing = 2
        backStack.alignment = .center
        backStack.translatesAutoresizingMaskIntoConstraints = false

        let backChevron = UIImageView(image: UIImage(systemName: "chevron.left"))
        backChevron.tintColor = UIColor(named: "ForHistory") ?? .systemPurple
        backChevron.contentMode = .scaleAspectFit
        backChevron.setContentHuggingPriority(.required, for: .horizontal)
        backChevron.widthAnchor.constraint(equalToConstant: 20).isActive = true
        backChevron.heightAnchor.constraint(equalToConstant: 20).isActive = true
        backStack.addArrangedSubview(backChevron)

        backButton.setTitle("Назад", for: .normal)
        backButton.setTitleColor(UIColor(named: "ForHistory") ?? .systemPurple, for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backStack.addArrangedSubview(backButton)
        view.addSubview(backStack)

        // TITLE
        titleLabel.text = "Анализ"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // FILTER CARD
        filterCard.backgroundColor = .white
        filterCard.layer.cornerRadius = 16
        filterCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterCard)

        filterStack.axis = .vertical
        filterStack.alignment = .fill
        filterStack.spacing = 12
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        filterCard.addSubview(filterStack)

        // FROM ROW
        periodFromRow.axis = .horizontal
        periodFromRow.alignment = .center
        periodFromRow.spacing = 8
        periodFromLabel.text = "Начало"
        periodFromLabel.font = .systemFont(ofSize: 17)
        periodFromValue.backgroundColor = UIColor(named: "AccentColorWithOpacity") ?? UIColor.systemGray5
        periodFromValue.layer.cornerRadius = 8
        periodFromValue.clipsToBounds = true
        periodFromRow.addArrangedSubview(periodFromLabel)
        periodFromRow.addArrangedSubview(UIView()) // spacer
        periodFromRow.addArrangedSubview(periodFromValue)

        // TO ROW
        periodToRow.axis = .horizontal
        periodToRow.alignment = .center
        periodToRow.spacing = 8
        periodToLabel.text = "Конец"
        periodToLabel.font = .systemFont(ofSize: 17)
        periodToValue.backgroundColor = UIColor(named: "AccentColorWithOpacity") ?? UIColor.systemGray5
        periodToValue.layer.cornerRadius = 8
        periodToValue.clipsToBounds = true
        periodToRow.addArrangedSubview(periodToLabel)
        periodToRow.addArrangedSubview(UIView()) // spacer
        periodToRow.addArrangedSubview(periodToValue)

        // SUM ROW
        sumRow.axis = .horizontal
        sumRow.alignment = .center
        sumRow.spacing = 8
        sumTitleLabel.text = "Сумма"
        sumTitleLabel.font = .systemFont(ofSize: 17)
        sumValueLabel.font = .systemFont(ofSize: 17, weight: .regular) // <<< НЕ жирный
        sumValueLabel.textAlignment = .right
        sumValueLabel.adjustsFontSizeToFitWidth = false
        sumValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        sumValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        sumRow.addArrangedSubview(sumTitleLabel)
        sumRow.addArrangedSubview(UIView()) // spacer
        sumRow.addArrangedSubview(sumValueLabel)

        // SORT
        sortControl.selectedSegmentIndex = 0

        // STACK CONTENT
        filterStack.addArrangedSubview(periodFromRow)
        filterStack.addArrangedSubview(periodToRow)
        filterStack.addArrangedSubview(sumRow)
        filterStack.addArrangedSubview(sortControl)

        // SECTION
        sectionLabel.text = "ОПЕРАЦИИ"
        sectionLabel.font = .systemFont(ofSize: 13, weight: .medium)
        sectionLabel.textColor = .secondaryLabel
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sectionLabel)

        // TABLE
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(AnalysisOperationCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle  = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // LOADER & ERROR
        activity.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        view.addSubview(activity)
        view.addSubview(errorLabel)

        // CONSTRAINTS
        NSLayoutConstraint.activate([
            backStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: backStack.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            filterCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            filterCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            filterStack.topAnchor.constraint(equalTo: filterCard.topAnchor, constant: 10),
            filterStack.leadingAnchor.constraint(equalTo: filterCard.leadingAnchor, constant: 16),
            filterStack.trailingAnchor.constraint(equalTo: filterCard.trailingAnchor, constant: -16),
            filterStack.bottomAnchor.constraint(equalTo: filterCard.bottomAnchor, constant: -10),

            sectionLabel.topAnchor.constraint(equalTo: filterCard.bottomAnchor, constant: 16),
            sectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            tableView.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.topAnchor.constraint(equalTo: filterCard.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Gestures / Targets
    private func setupGestures() {
        let tapFrom = UITapGestureRecognizer(target: self, action: #selector(showFromCalendar))
        periodFromValue.isUserInteractionEnabled = true
        periodFromValue.addGestureRecognizer(tapFrom)

        let tapTo = UITapGestureRecognizer(target: self, action: #selector(showToCalendar))
        periodToValue.isUserInteractionEnabled = true
        periodToValue.addGestureRecognizer(tapTo)

        sortControl.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
    }

    // MARK: - Actions
    @objc private func backTapped() {
        dismiss(animated: true)
    }

    @objc private func sortChanged() {
        sortKind = (sortControl.selectedSegmentIndex == 0) ? .date : .amount
        reloadData()
    }

    @objc private func showFromCalendar() {
        presentCalendar(for: dateFrom, sourceView: periodFromValue) { [weak self] date in
            guard let self else { return }
            if date > dateTo { dateTo = date }
            dateFrom = date
            applyPeriodLabels()
            reloadData()
        }
    }

    @objc private func showToCalendar() {
        presentCalendar(for: dateTo, sourceView: periodToValue) { [weak self] date in
            guard let self else { return }
            if date < dateFrom { dateFrom = date }
            dateTo = date
            applyPeriodLabels()
            reloadData()
        }
    }

    // MARK: - Calendar sheet presentation
    private func presentCalendar(for selected: Date,
                                 sourceView: UIView,
                                 onPick: @escaping (Date) -> Void) {
        let anchor = sourceView.convert(sourceView.bounds, to: view)
        let vc = SimpleCalendarSheetViewController(selected: selected, anchorRect: anchor)
        vc.onDateSelected = onPick
        present(vc, animated: true)
    }

    // MARK: - Period labels
    private func applyPeriodLabels() {
        periodFromValue.text = formattedMonth(dateFrom)
        periodToValue.text   = formattedMonth(dateTo)
    }

    private func formattedMonth(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "dd MMMM"
        return df.string(from: date)
    }

    // MARK: - Categories (network)
    func loadCategories(force: Bool = false) {
        Task {
            if force || categoriesService.categories.isEmpty {
                await categoriesService.loadCategories(force: force)
            }
            await MainActor.run {
                self.categories = Dictionary(uniqueKeysWithValues: categoriesService.categories.map { ($0.id, $0) })
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Reload data (network)
    private func reloadData() {
        Task {
            await MainActor.run { self.setLoading(true, message: nil) }

            if accountService.account == nil {
                await accountService.loadMainAccount()
            }
            guard accountService.account != nil else {
                await MainActor.run { self.setLoading(false, message: "Счёт не найден.") }
                return
            }

            await txService.loadTransactions(startDate: self.dateFrom, endDate: self.dateTo)
            let txs = txService.transactions

            let sorted: [Transaction]
            switch self.sortKind {
            case .date:   sorted = txs.sorted { $0.transactionDate > $1.transactionDate }
            case .amount: sorted = txs.sorted { $0.amount > $1.amount }
            }

            let total = sorted.reduce(Decimal.zero) { $0 + $1.amount }

            await MainActor.run {
                self.transactions = sorted
                self.totalSum     = total

                // гарантированно НЕ жирный
                self.sumValueLabel.attributedText = nil
                self.sumValueLabel.text = self.totalSum.formattedAmount
                self.sumValueLabel.font = .systemFont(ofSize: 17, weight: .regular)

                self.errorLabel.text    = nil
                self.tableView.reloadData()
                self.setLoading(false, message: nil)
            }
        }
    }

    // MARK: - Loading / Error UI
    @MainActor
    private func setLoading(_ loading: Bool, message: String?) {
        if loading {
            activity.startAnimating()
            errorLabel.text = nil
        } else {
            activity.stopAnimating()
            errorLabel.text = message
        }
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate
extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tx = transactions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AnalysisOperationCell
        let cat = categories[tx.categoryId]
        let total = (totalSum as NSDecimalNumber).doubleValue
        let percent = total > 0
            ? (tx.amount as NSDecimalNumber).doubleValue / total * 100.0
            : 0
        let isTop = indexPath.row == 0
        let isBottom = indexPath.row == transactions.count - 1
        cell.configure(with: tx, category: cat, percent: percent, isTop: isTop, isBottom: isBottom)
        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // По тапу можно открывать подробности / фильтрацию — оставляю на будущее.
    }
}

// MARK: - Аналитическая ячейка
final class AnalysisOperationCell: UITableViewCell {
    private let iconBackground = UIView()
    private let iconLabel     = UILabel()
    private let titleLabel    = UILabel()
    private let subtitleLabel = UILabel()
    private let amountStack   = UIStackView()
    private let percentLabel  = UILabel()
    private let amountLabel   = UILabel()
    private let chevron       = UIImageView(image: UIImage(named: "Arrow"))
    private let stack         = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.backgroundColor = .white

        iconBackground.backgroundColor = UIColor(named: "AccentColorWithOpacity") ?? UIColor.systemGray5
        iconBackground.layer.cornerRadius = 20
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconBackground.heightAnchor.constraint(equalToConstant: 40).isActive = true

        iconLabel.font = .systemFont(ofSize: 20)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(iconLabel)
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor)
        ])

        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .black
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        amountStack.axis = .vertical
        amountStack.alignment = .trailing
        amountStack.spacing = 2

        percentLabel.font = .systemFont(ofSize: 13)
        percentLabel.textColor = .secondaryLabel

        amountLabel.font = .systemFont(ofSize: 17)
        amountLabel.textAlignment = .right

        amountStack.addArrangedSubview(percentLabel)
        amountStack.addArrangedSubview(amountLabel)

        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 20).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(iconBackground)
        stack.addArrangedSubview(textStack)
        stack.addArrangedSubview(UIView()) // spacer
        stack.addArrangedSubview(amountStack)
        stack.addArrangedSubview(chevron)

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with tx: Transaction,
                   category: Category?,
                   percent: Double,
                   isTop: Bool,
                   isBottom: Bool) {
        iconLabel.text = category?.emoji ?? "⬜️"
        titleLabel.text = category?.name ?? "Категория"
        subtitleLabel.text = tx.comment
        amountLabel.text = tx.amount.formattedAmount
        percentLabel.text = String(format: "%.0f%%", percent)

        if #available(iOS 11.0, *) {
            var masked: CACornerMask = []
            if isTop { masked.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
            if isBottom { masked.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
            if masked.isEmpty {
                contentView.layer.cornerRadius = 0
                contentView.layer.maskedCorners = []
            } else {
                contentView.layer.cornerRadius = 16
                contentView.layer.maskedCorners = masked
            }
        }
    }
}

// MARK: - PaddedLabel (микро-отступы вокруг текста)
final class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    override var intrinsicContentSize: CGSize {
        var s = super.intrinsicContentSize
        s.width  += textInsets.left + textInsets.right
        s.height += textInsets.top  + textInsets.bottom
        return s
    }
}
