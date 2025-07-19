import UIKit

final class AnalysisViewController: UIViewController {
    // MARK: - UI
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let filterCard = UIView()
    private let filterStack = UIStackView()
    private let periodFromRow = UIStackView()
    private let periodToRow = UIStackView()
    private let periodFromLabel = UILabel()
    private let periodToLabel = UILabel()
    private let periodFromValue = PaddedLabel()
    private let periodToValue = PaddedLabel()
    private let sumRow = UIStackView()
    private let sumTitleLabel = UILabel()
    private let sumValueLabel = UILabel()
    private let sortControl = UISegmentedControl(items: ["Дата", "Сумма"])
    private let tableView = UITableView()
    private let sectionLabel = UILabel()
    private let calendarView = SimpleCalendarView()
    
    // MARK: - Data
    private var transactions: [Transaction] = []
    private var categories: [Int: Category] = [:]
    private var sortKind: SortKind = .date
    private var dateFrom = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    private var dateTo = Date()
    private var totalSum: Decimal = 0
    
    enum SortKind { case date, amount }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        setupUI()
        loadCategories()
        reloadData()
        setupCalendarGestures()
    }
    
    private func setupUI() {
  
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
        
 
        titleLabel.text = "Анализ"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        

        filterCard.backgroundColor = .white
        filterCard.layer.cornerRadius = 16
        filterCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterCard)
        
   
        filterStack.axis = .vertical
        filterStack.spacing = 0
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        filterCard.addSubview(filterStack)
        
     
        periodFromRow.axis = .horizontal
        periodFromRow.alignment = .center
        periodFromRow.isLayoutMarginsRelativeArrangement = false
        periodFromLabel.text = "Период: начало"
        periodFromLabel.font = .systemFont(ofSize: 17)
        periodFromValue.text = formattedMonth(dateFrom)
        periodFromValue.font = .systemFont(ofSize: 17)
        periodFromValue.textColor = .black
        periodFromValue.backgroundColor = UIColor(named: "AccentColorWithOpacity") ?? UIColor.systemGreen.withAlphaComponent(0.2)
        periodFromValue.heightAnchor.constraint(equalToConstant: 32).isActive = true
        periodFromValue.layer.cornerRadius = 8
        periodFromValue.clipsToBounds = true
        periodFromValue.textAlignment = .center
        periodFromValue.isUserInteractionEnabled = true
        periodFromValue.setContentHuggingPriority(.required, for: .horizontal)
        periodFromRow.addArrangedSubview(periodFromLabel)
        periodFromRow.addArrangedSubview(UIView())
        periodFromRow.addArrangedSubview(periodFromValue)
        filterStack.addArrangedSubview(periodFromRow)
     
        let spacer1 = UIView()
        spacer1.translatesAutoresizingMaskIntoConstraints = false
        spacer1.heightAnchor.constraint(equalToConstant: 8).isActive = true
        filterStack.addArrangedSubview(spacer1)
       
        let divider1 = UIView()
        divider1.backgroundColor = UIColor.systemGray4
        divider1.translatesAutoresizingMaskIntoConstraints = false
        divider1.heightAnchor.constraint(equalToConstant: 0.7).isActive = true
        filterStack.addArrangedSubview(divider1)
       
        let spacer2 = UIView()
        spacer2.translatesAutoresizingMaskIntoConstraints = false
        spacer2.heightAnchor.constraint(equalToConstant: 8).isActive = true
        filterStack.addArrangedSubview(spacer2)
  
        periodToRow.axis = .horizontal
        periodToRow.alignment = .center
        periodToRow.isLayoutMarginsRelativeArrangement = false
        periodToLabel.text = "Период: конец"
        periodToLabel.font = .systemFont(ofSize: 17)
        periodToValue.text = formattedMonth(dateTo)
        periodToValue.font = .systemFont(ofSize: 17)
        periodToValue.textColor = .black
        periodToValue.backgroundColor = UIColor(named: "AccentColorWithOpacity") ?? UIColor.systemGreen.withAlphaComponent(0.2)
        periodToValue.heightAnchor.constraint(equalToConstant: 32).isActive = true
        periodToValue.layer.cornerRadius = 8
        periodToValue.clipsToBounds = true
        periodToValue.textAlignment = .center
        periodToValue.isUserInteractionEnabled = true
        periodToValue.setContentHuggingPriority(.required, for: .horizontal)
        periodToRow.addArrangedSubview(periodToLabel)
        periodToRow.addArrangedSubview(UIView())
        periodToRow.addArrangedSubview(periodToValue)
        filterStack.addArrangedSubview(periodToRow)
 
        let spacer3 = UIView()
        spacer3.translatesAutoresizingMaskIntoConstraints = false
        spacer3.heightAnchor.constraint(equalToConstant: 8).isActive = true
        filterStack.addArrangedSubview(spacer3)
   
        let divider2 = UIView()
        divider2.backgroundColor = UIColor.systemGray4
        divider2.translatesAutoresizingMaskIntoConstraints = false
        divider2.heightAnchor.constraint(equalToConstant: 0.7).isActive = true
        filterStack.addArrangedSubview(divider2)
    
        let spacer4 = UIView()
        spacer4.translatesAutoresizingMaskIntoConstraints = false
        spacer4.heightAnchor.constraint(equalToConstant: 8).isActive = true
        filterStack.addArrangedSubview(spacer4)
      
        let sortRow = UIStackView()
        sortRow.axis = .horizontal
        sortRow.alignment = .center
        sortRow.spacing = 12
        let sortLabel = UILabel()
        sortLabel.text = "Сортировка"
        sortLabel.font = .systemFont(ofSize: 17)
        sortLabel.textColor = .label
        sortLabel.setContentHuggingPriority(.required, for: .vertical)
        let sortBG = UIView()
        sortBG.backgroundColor = UIColor.systemGray6
        sortBG.layer.cornerRadius = 10
        sortBG.translatesAutoresizingMaskIntoConstraints = false
        sortBG.addSubview(sortControl)
        sortControl.translatesAutoresizingMaskIntoConstraints = false
        sortControl.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
        NSLayoutConstraint.activate([
            sortControl.centerYAnchor.constraint(equalTo: sortBG.centerYAnchor),
            sortControl.topAnchor.constraint(greaterThanOrEqualTo: sortBG.topAnchor, constant: 0),
            sortControl.bottomAnchor.constraint(lessThanOrEqualTo: sortBG.bottomAnchor, constant: 0),
            sortControl.leadingAnchor.constraint(equalTo: sortBG.leadingAnchor, constant: 0),
            sortControl.trailingAnchor.constraint(equalTo: sortBG.trailingAnchor, constant: 0),
            sortBG.widthAnchor.constraint(equalToConstant: 150),
            sortBG.heightAnchor.constraint(equalToConstant: 32),
        ])
        sortRow.addArrangedSubview(sortLabel)
        sortRow.addArrangedSubview(sortBG)
        filterStack.addArrangedSubview(sortRow)
        // Spacer after sortRow (20pt)
        let sortSpacer = UIView()
        sortSpacer.translatesAutoresizingMaskIntoConstraints = false
        sortSpacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        filterStack.addArrangedSubview(sortSpacer)
 
        let divider3 = UIView()
        divider3.backgroundColor = UIColor.systemGray4
        divider3.translatesAutoresizingMaskIntoConstraints = false
        divider3.heightAnchor.constraint(equalToConstant: 0.7).isActive = true
        filterStack.addArrangedSubview(divider3)
     
        let spacer6 = UIView()
        spacer6.translatesAutoresizingMaskIntoConstraints = false
        spacer6.heightAnchor.constraint(equalToConstant: 14).isActive = true
        filterStack.addArrangedSubview(spacer6)
   
        sumRow.axis = .horizontal
        sumRow.alignment = .center
        sumRow.isLayoutMarginsRelativeArrangement = false
        sumTitleLabel.text = "Сумма"
        sumTitleLabel.font = .systemFont(ofSize: 17)
        sumValueLabel.font = .systemFont(ofSize: 17, weight: .regular)
        sumValueLabel.textColor = .black
        sumRow.addArrangedSubview(sumTitleLabel)
        sumRow.addArrangedSubview(UIView())
        sumRow.addArrangedSubview(sumValueLabel)
        filterStack.addArrangedSubview(sumRow)
        

        sectionLabel.text = "Операции"
        sectionLabel.font = .systemFont(ofSize: 13, weight: .medium)
        sectionLabel.textColor = .secondaryLabel
        sectionLabel.textAlignment = .left
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sectionLabel)
        
       
        tableView.dataSource = self
        tableView.register(AnalysisOperationCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
 
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
            
            sectionLabel.topAnchor.constraint(equalTo: filterCard.bottomAnchor, constant: 32),
            sectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            sectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            tableView.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCalendarGestures() {
        periodFromValue.isUserInteractionEnabled = true
        let tapFrom = UITapGestureRecognizer(target: self, action: #selector(showFromCalendar))
        periodFromValue.addGestureRecognizer(tapFrom)
        periodToValue.isUserInteractionEnabled = true
        let tapTo = UITapGestureRecognizer(target: self, action: #selector(showToCalendar))
        periodToValue.addGestureRecognizer(tapTo)
    }
    
    // MARK: - Data
    private func loadCategories() {
        Task {
            if let cats = try? await CategoriesService.shared.getAllCategories() {
                self.categories = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
                self.reloadData()
            }
        }
    }
    
    private func reloadData() {
        Task {
            let all = try? await TransactionsService.shared.fetch(from: dateFrom, to: dateTo)
            let txs = all ?? []
            self.transactions = sortKind == .date
                ? txs.sorted { $0.transactionDate > $1.transactionDate }
                : txs.sorted { $0.amount > $1.amount }
            self.totalSum = self.transactions.reduce(0) { $0 + $1.amount }
            DispatchQueue.main.async {
                self.periodFromValue.text = self.formattedMonth(self.dateFrom)
                self.periodToValue.text = self.formattedMonth(self.dateTo)
                self.sumValueLabel.text = self.totalSum.formattedAmount
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sortChanged() {
        sortKind = sortControl.selectedSegmentIndex == 0 ? .date : .amount
        reloadData()
    }
    
    @objc private func showFromCalendar() {
        guard let window = self.view.window else { return }
        let rect = periodFromValue.convert(periodFromValue.bounds, to: window)
        let calendarVC = SimpleCalendarSheetViewController(selected: dateFrom, anchorRect: rect)
        calendarVC.onDateSelected = { [weak self] (date: Date) in
            guard let self = self else { return }
            self.dateFrom = date
            if self.dateFrom > self.dateTo { self.dateTo = self.dateFrom }
            self.periodFromValue.text = self.formattedMonth(self.dateFrom)
            self.reloadData()
        }
        present(calendarVC, animated: true)
    }
    @objc private func showToCalendar() {
        guard let window = self.view.window else { return }
        let rect = periodToValue.convert(periodToValue.bounds, to: window)
        let calendarVC = SimpleCalendarSheetViewController(selected: dateTo, anchorRect: rect)
        calendarVC.onDateSelected = { [weak self] (date: Date) in
            guard let self = self else { return }
            self.dateTo = date
            if self.dateTo < self.dateFrom { self.dateFrom = self.dateTo }
            self.periodToValue.text = self.formattedMonth(self.dateTo)
            self.reloadData()
        }
        present(calendarVC, animated: true)
    }
    
    // MARK: - Helpers
    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }
}

// MARK: - UITableViewDataSource
extension AnalysisViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tx = transactions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AnalysisOperationCell
        let cat = categories[tx.categoryId]
        let percent = totalSum > 0 ? Double((tx.amount as NSDecimalNumber).doubleValue / (totalSum as NSDecimalNumber).doubleValue) * 100 : 0
        let isTop = indexPath.row == 0
        let isBottom = indexPath.row == transactions.count - 1
        cell.configure(with: tx, category: cat, percent: percent, isTop: isTop, isBottom: isBottom)
        return cell
    }
}

// MARK: - AnalysisOperationCell
final class AnalysisOperationCell: UITableViewCell {
    private let iconBackground = UIView()
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let amountStack = UIStackView()
    private let amountLabel = UILabel()
    private let percentLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(named: "Arrow"))
    private let stack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 0 // по умолчанию без скругления
        contentView.layer.masksToBounds = true
        
        iconBackground.backgroundColor = UIColor(named: "AccentColorWithOpacity") ?? UIColor.systemGreen.withAlphaComponent(0.2)
        iconBackground.layer.cornerRadius = 14
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.widthAnchor.constraint(equalToConstant: 28).isActive = true
        iconBackground.heightAnchor.constraint(equalToConstant: 28).isActive = true
        iconLabel.font = .systemFont(ofSize: 16)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(iconLabel)
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor)
        ])
        iconBackground.setContentHuggingPriority(.required, for: .horizontal)
        
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .black
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        
        amountStack.axis = .vertical
        amountStack.alignment = .trailing
        amountStack.spacing = 2
        amountStack.setContentHuggingPriority(.required, for: .horizontal)
        
        percentLabel.font = .systemFont(ofSize: 13, weight: .regular)
        percentLabel.textColor = .secondaryLabel
        percentLabel.textAlignment = .right
        amountLabel.font = .systemFont(ofSize: 17, weight: .regular)
        amountLabel.textAlignment = .right
        amountStack.addArrangedSubview(percentLabel)
        amountStack.addArrangedSubview(amountLabel)
        
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        stack.addArrangedSubview(iconBackground)
        stack.addArrangedSubview(textStack)
        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(amountStack)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 16).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 36).isActive = true
        stack.addArrangedSubview(chevron)
        
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with tx: Transaction, category: Category?, percent: Double, isTop: Bool = false, isBottom: Bool = false) {
        iconLabel.text = category?.emoji ?? "⬜️"
        titleLabel.text = category?.name ?? "Категория"
        subtitleLabel.text = tx.comment
        amountLabel.text = tx.amount.formattedAmount
        percentLabel.text = String(format: "%.0f%%", percent)
        // Скругление только нужных углов
        if #available(iOS 11.0, *) {
            if isTop && isBottom {
                contentView.layer.cornerRadius = 16
                contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else if isTop {
                contentView.layer.cornerRadius = 16
                contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            } else if isBottom {
                contentView.layer.cornerRadius = 16
                contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                contentView.layer.cornerRadius = 0
            }
        }
    }
}


class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
}
