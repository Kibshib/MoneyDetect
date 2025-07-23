import UIKit


final class SimpleCalendarSheetViewController: UIViewController {


    var onDateSelected: ((Date) -> Void)?

    private let calendarView = SimpleCalendarView()


    private let selected: Date


    private let anchorRect: CGRect

    private let dismissView = UIView()

    private let container = UIView()


    init(selected: Date, anchorRect: CGRect) {
        self.selected = selected
        self.anchorRect = anchorRect
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupDismissView()
        setupPopup()
    }


    private func setupDismissView() {
        dismissView.backgroundColor = .clear
        dismissView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissView)
        NSLayoutConstraint.activate([
            dismissView.topAnchor.constraint(equalTo: view.topAnchor),
            dismissView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dismissView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dismissView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        dismissView.addGestureRecognizer(tap)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    private func setupPopup() {
   
        container.backgroundColor = .white
        container.layer.cornerRadius = 24
        container.layer.masksToBounds = false
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowRadius = 24
        container.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(container)


        let popupWidth: CGFloat = 340
        let cellHeight: CGFloat = 38
        let headerHeight: CGFloat = 32
        let daysOfWeekHeight: CGFloat = 24
        let verticalSpacing: CGFloat = 8 + 8

        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: selected)
        let firstOfMonth = calendar.date(from: comps) ?? selected
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        let filledDays = daysInMonth + max(firstWeekday, 0)
        let rows = Int(ceil(Double(filledDays) / 7.0))
        let popupHeight = headerHeight + daysOfWeekHeight + CGFloat(rows) * cellHeight + verticalSpacing + 16 + 16


        let screen = UIScreen.main.bounds
        let minX: CGFloat = 16
        let maxX: CGFloat = screen.width - popupWidth - 16
        var x = anchorRect.midX - popupWidth / 2
        if x < minX { x = minX }
        if x > maxX { x = maxX }
        var y = anchorRect.maxY + 8
        let maxY = screen.height - popupHeight - 8
        if y > maxY { y = maxY }
        container.frame = CGRect(x: x, y: y, width: popupWidth, height: popupHeight)


        calendarView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            calendarView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        calendarView.selectedDate = selected
        calendarView.onDateSelected = { [weak self] (date: Date) in
            guard let self else { return }
            self.onDateSelected?(date)
            self.dismiss(animated: true)
        }
    }
}
