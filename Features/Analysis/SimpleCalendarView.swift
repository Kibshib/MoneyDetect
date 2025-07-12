

import UIKit

final class SimpleCalendarView: UIView {
    // MARK: - Public
    var onDateSelected: ((Date) -> Void)?
    var selectedDate: Date = Date() {
        didSet { setNeedsLayout(); collectionView.reloadData() }
    }

    // MARK: - Private
    private var calendar = Calendar.current
    private var currentMonth: Date
    private let monthLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let daysStack = UIStackView()
    private let collectionView: UICollectionView

    override init(frame: CGRect) {
        self.currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
        updateMonth()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        // Header
        monthLabel.font = .boldSystemFont(ofSize: 20)
        monthLabel.textColor = .black
        monthLabel.textAlignment = .center

        prevButton.setTitle("<", for: .normal)
        prevButton.setTitleColor(.systemGreen, for: .normal)
        prevButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)

        nextButton.setTitle(">", for: .normal)
        nextButton.setTitleColor(.systemGreen, for: .normal)
        nextButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [prevButton, monthLabel, nextButton])
        headerStack.axis = .horizontal
        headerStack.distribution = .equalCentering
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerStack)

        // Days of week
        daysStack.axis = .horizontal
        daysStack.distribution = .fillEqually
        daysStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(daysStack)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        let days = df.shortWeekdaySymbols ?? ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        for (i, d) in days.enumerated() {
            let l = UILabel()
            l.text = d.uppercased()
            l.font = .systemFont(ofSize: 13, weight: .medium)
            l.textColor = (i == 6) ? UIColor.systemPurple : .systemGray // Saturday highlight
            l.textAlignment = .center
            daysStack.addArrangedSubview(l)
        }

        // CollectionView
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: "DayCell")
        addSubview(collectionView)

        // Layout
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            headerStack.heightAnchor.constraint(equalToConstant: 32),

            daysStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            daysStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            daysStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            daysStack.heightAnchor.constraint(equalToConstant: 24),

            collectionView.topAnchor.constraint(equalTo: daysStack.bottomAnchor, constant: 2),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    private func updateMonth() {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "LLLL yyyy"
        monthLabel.text = df.string(from: currentMonth).capitalized
        collectionView.reloadData()
    }

    @objc private func prevMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = newMonth
        updateMonth()
    }
    @objc private func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = newMonth
        updateMonth()
    }
}

// MARK: - UICollectionViewDataSource, Delegate
extension SimpleCalendarView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let closed = calendar.range(of: .day, in: .month, for: currentMonth) ?? 1..<31
        let first = calendar.component(.weekday, from: currentMonth) - 1 
        return Array(closed).count + max(first, 0)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DayCell
        let closed = calendar.range(of: .day, in: .month, for: currentMonth) ?? 1..<31
        let days = Array(closed)
        let first = calendar.component(.weekday, from: currentMonth) - 1
        if indexPath.item < max(first, 0) {
            cell.configure(day: nil, isSelected: false, isToday: false, accent: .systemGreen, highlight: .systemPurple)
        } else {
            let dayIndex = indexPath.item - max(first, 0)
            guard dayIndex >= 0 && dayIndex < days.count else {
                cell.configure(day: nil, isSelected: false, isToday: false, accent: .systemGreen, highlight: .systemPurple)
                return cell
            }
            let day = days[dayIndex]
            var comps = calendar.dateComponents([.year, .month], from: currentMonth)
            comps.day = day
            guard let date = calendar.date(from: comps) else {
                cell.configure(day: day, isSelected: false, isToday: false, accent: .systemGreen, highlight: .systemPurple)
                return cell
            }
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            let isToday = calendar.isDateInToday(date)
            cell.configure(day: day, isSelected: isSelected, isToday: isToday, accent: .systemGreen, highlight: .systemPurple)
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = (collectionView.bounds.width) / 7
        return CGSize(width: w, height: 38)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let closed = calendar.range(of: .day, in: .month, for: currentMonth) ?? 1..<31
        let days = Array(closed)
        let first = calendar.component(.weekday, from: currentMonth) - 1
        if indexPath.item < max(first, 0) { return }
        let dayIndex = indexPath.item - max(first, 0)
        guard dayIndex >= 0 && dayIndex < days.count else { return }
        let day = days[dayIndex]
        var comps = calendar.dateComponents([.year, .month], from: currentMonth)
        comps.day = day
        guard let date = calendar.date(from: comps) else { return }
        selectedDate = date
        onDateSelected?(date)
        collectionView.reloadData()
    }
}

// MARK: - DayCell
private class DayCell: UICollectionViewCell {
    private let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        label.font = .systemFont(ofSize: 18, weight: .regular)
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(day: Int?, isSelected: Bool, isToday: Bool, accent: UIColor, highlight: UIColor) {
        if let d = day {
            label.text = "\(d)"
            if isSelected {
                label.textColor = accent
                contentView.backgroundColor = accent.withAlphaComponent(0.15)
                contentView.layer.cornerRadius = 19
            } else if isToday {
                label.textColor = accent
                contentView.backgroundColor = .clear
            } else {
                label.textColor = .black
                contentView.backgroundColor = .clear
            }
        } else {
            label.text = ""
            contentView.backgroundColor = .clear
        }
    }
}
