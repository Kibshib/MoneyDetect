import UIKit

final class SimpleCalendarSheetViewController: UIViewController {
    var onDateSelected: ((Date) -> Void)?
    private let calendarView = SimpleCalendarView()
    private let selected: Date
    private let container = UIView()
    private let anchorRect: CGRect
    private let dismissView = UIView()

    init(selected: Date, anchorRect: CGRect) {
        self.selected = selected
        self.anchorRect = anchorRect
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError() }

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
        let closed = calendar.range(of: .day, in: .month, for: selected) ?? 1..<31
        let comps = calendar.dateComponents([.year, .month], from: selected)
        let firstOfMonth = calendar.date(from: comps) ?? selected
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        let daysCount = Array(closed).count + max(firstWeekday, 0)
        let numberOfRows = Int(ceil(Double(daysCount) / 7.0))
        let popupHeight = headerHeight + daysOfWeekHeight + (CGFloat(numberOfRows) * cellHeight) + verticalSpacing + 16 + 16 
        let screenBounds = UIScreen.main.bounds
        var x = anchorRect.midX - popupWidth / 2
        let minX: CGFloat = 8
        let maxX = screenBounds.width - popupWidth - 8
        if x < minX { x = minX }
        if x > maxX { x = maxX }
        var y = anchorRect.maxY + 8
        let maxY = screenBounds.height - popupHeight - 8
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
        calendarView.onDateSelected = { [weak self] date in
            self?.onDateSelected?(date)
            self?.dismiss(animated: true)
        }
    }
} 
