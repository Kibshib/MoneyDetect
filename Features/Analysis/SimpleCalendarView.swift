import UIKit

final class SimpleCalendarView: UIView {


    var onDateSelected: ((Date) -> Void)?
    var selectedDate: Date = Date() {
        didSet { collectionView.reloadData(); updateMonthLabel() }
    }


    private var calendar = Calendar.current
    private var currentMonth: Date

    private let monthLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let daysStack  = UIStackView()
    private let collectionView: UICollectionView

    override init(frame: CGRect) {
        self.currentMonth = calendar.date(from: calendar.dateComponents([.year,.month], from: Date())) ?? Date()
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        self.currentMonth = calendar.date(from: calendar.dateComponents([.year,.month], from: Date())) ?? Date()
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        calendar.locale = Locale(identifier: "ru_RU")

 
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        addSubview(header)

        prevButton.setTitle("<", for: .normal)
        prevButton.setTitleColor(UIColor(named: "ForHistory") ?? .systemGreen, for: .normal)
        prevButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .regular)
        prevButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)

        nextButton.setTitle(">", for: .normal)
        nextButton.setTitleColor(UIColor(named: "ForHistory") ?? .systemGreen, for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .regular)
        nextButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)

        monthLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        monthLabel.textAlignment = .center

        header.addSubview(prevButton)
        header.addSubview(monthLabel)
        header.addSubview(nextButton)
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false


        daysStack.axis = .horizontal
        daysStack.alignment = .fill
        daysStack.distribution = .fillEqually
        daysStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(daysStack)

        let df = DateFormatter()
        df.locale = calendar.locale
        let raw = df.shortWeekdaySymbols ?? ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]
        let firstIdx = calendar.firstWeekday - 1
        let ordered = Array(raw[firstIdx...] + raw[..<firstIdx])
        for (i, d) in ordered.enumerated() {
            let l = UILabel()
            l.text = d.uppercased()
            l.font = .systemFont(ofSize: 13, weight: .medium)
            l.textColor = (i >= 5)
                ? (UIColor(named: "ForHistory") ?? .systemPurple)
                : .secondaryLabel
            l.textAlignment = .center
            daysStack.addArrangedSubview(l)
        }

 
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.register(CalendarDayCell.self, forCellWithReuseIdentifier: "day")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)


        NSLayoutConstraint.activate([
    
            header.topAnchor.constraint(equalTo: topAnchor),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            header.heightAnchor.constraint(equalToConstant: 32),

            prevButton.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            prevButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 32),
            prevButton.heightAnchor.constraint(equalToConstant: 32),

            nextButton.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            nextButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 32),
            nextButton.heightAnchor.constraint(equalToConstant: 32),

            monthLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            monthLabel.leadingAnchor.constraint(greaterThanOrEqualTo: prevButton.trailingAnchor, constant: 4),
            monthLabel.trailingAnchor.constraint(lessThanOrEqualTo: nextButton.leadingAnchor, constant: -4),

            daysStack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            daysStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            daysStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),


            collectionView.topAnchor.constraint(equalTo: daysStack.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 6 * 38)
        ])

        updateMonthLabel()
    }


    @objc private func prevMonth() {
        if let new = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = new
            collectionView.reloadData()
            updateMonthLabel()
        }
    }

    @objc private func nextMonth() {
        if let new = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = new
            collectionView.reloadData()
            updateMonthLabel()
        }
    }

    private func updateMonthLabel() {
        let df = DateFormatter()
        df.locale = calendar.locale
        df.dateFormat = "LLLL yyyy"
        monthLabel.text = df.string(from: currentMonth).capitalized
    }


    private func daysInCurrentMonth() -> Int {
        calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
    }
    private func firstWeekdayOffset() -> Int {
        let first = currentMonth
        let wd = calendar.component(.weekday, from: first) - calendar.firstWeekday
        return (wd + 7) % 7
    }
}

extension SimpleCalendarView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        firstWeekdayOffset() + daysInCurrentMonth()
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "day", for: indexPath) as! CalendarDayCell
        let offset = firstWeekdayOffset()
        if indexPath.item < offset {
            cell.configure(day: nil, isSelected: false, isToday: false,
                           accent: UIColor(named: "ForHistory") ?? .systemPurple,
                           highlight: UIColor(named: "AccentColorWithOpacity") ?? .systemGray5)
        } else {
            let day = indexPath.item - offset + 1
            var comps = calendar.dateComponents([.year,.month], from: currentMonth)
            comps.day = day
            let date = calendar.date(from: comps) ?? currentMonth
            let isSel = calendar.isDate(date, inSameDayAs: selectedDate)
            let isToday = calendar.isDateInToday(date)
            cell.configure(day: day, isSelected: isSel, isToday: isToday,
                           accent: UIColor(named: "ForHistory") ?? .systemPurple,
                           highlight: UIColor(named: "AccentColorWithOpacity") ?? .systemGray5)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let offset = firstWeekdayOffset()
        guard indexPath.item >= offset else { return }
        let day = indexPath.item - offset + 1
        var comps = calendar.dateComponents([.year,.month], from: currentMonth)
        comps.day = day
        let date = calendar.date(from: comps) ?? currentMonth
        selectedDate = date
        onDateSelected?(date)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.bounds.width / 7.0
        return CGSize(width: floor(w), height: 38)
    }
}


private final class CalendarDayCell: UICollectionViewCell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        label.font = .systemFont(ofSize: 18, weight: .regular)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(day: Int?,
                   isSelected: Bool,
                   isToday: Bool,
                   accent: UIColor,
                   highlight: UIColor) {
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
