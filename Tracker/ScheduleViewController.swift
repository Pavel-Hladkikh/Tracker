import UIKit

final class ScheduleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let side: CGFloat = 16
    private let titleTop: CGFloat = 38
    private let titleToTableSpacing: CGFloat = 30
    private let tableToButtonSpacing: CGFloat = 47
    private let buttonBottom: CGFloat = 16
    private let buttonHeight: CGFloat = 60
    private let corner: CGFloat = 16
    
    private let titleBlack: UIColor = Colors.baseInverse
    private let cardGray: UIColor   = Colors.cardStroke
    
    private var selectedWeekdays: Set<Weekday>
    var onDone: ((Set<Weekday>) -> Void)?
    
    private let titleLabel = UILabel()
    private let containerView  = UIView()
    private let tableView  = UITableView(frame: .zero, style: .plain)
    private let doneButton = UIButton(type: .system)
    
    init(selected: Set<Weekday>) {
        self.selectedWeekdays = selected
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.base
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupTitleLabel()
        setupContainerAndTable()
        setupDoneButton()
        setupLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let height = containerView.bounds.height
        guard height > 0 else { return }
        let rowHeight = floor(height / 7.0)
        if abs(tableView.rowHeight - rowHeight) > 0.5 {
            tableView.rowHeight = rowHeight
            tableView.estimatedRowHeight = rowHeight
            tableView.reloadData()
        }
    }
    
    private func setupTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("schedule_title", comment: "")
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = titleBlack
        view.addSubview(titleLabel)
    }
    
    private func setupContainerAndTable() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = cardGray
        containerView.layer.cornerRadius = corner
        containerView.layer.masksToBounds = true
        view.addSubview(containerView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = true
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "dayCell")
        tableView.tableFooterView = UIView(frame: .zero)
        
        containerView.addSubview(tableView)
    }
    
    private func setupDoneButton() {
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle(NSLocalizedString("done_button_title", comment: ""), for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        doneButton.layer.cornerRadius = corner
        doneButton.layer.masksToBounds = true
        doneButton.backgroundColor = Colors.baseInverse
        doneButton.setTitleColor(Colors.base, for: .normal)
        doneButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        view.addSubview(doneButton)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: titleTop),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),
            
            containerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: titleToTableSpacing),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),
            
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: side),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -side),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -buttonBottom),
            
            containerView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -tableToButtonSpacing)
        ])
    }
    
    @objc private func doneTapped() {
        onDone?(selectedWeekdays)
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Weekday.uiOrder.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let day = Weekday.uiOrder[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "dayCell", for: indexPath)
        var config = UIListContentConfiguration.valueCell()
        config.text = day.ruFull
        config.textProperties.font = .systemFont(ofSize: 17, weight: .regular)
        config.textProperties.color = titleBlack
        cell.contentConfiguration = config
        
        let daySwitch = UISwitch()
        daySwitch.onTintColor = .systemBlue
        daySwitch.isOn = selectedWeekdays.contains(day)
        daySwitch.tag = day.rawValue
        daySwitch.addTarget(self, action: #selector(toggleSwitch(_:)), for: .valueChanged)
        cell.accessoryView = daySwitch
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastIndex = Weekday.uiOrder.count - 1
        if indexPath.row == lastIndex {
            let rightInset = tableView.bounds.width + 100
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: rightInset)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
    
    @objc private func toggleSwitch(_ sender: UISwitch) {
        guard let day = Weekday(rawValue: sender.tag) else { return }
        if sender.isOn {
            selectedWeekdays.insert(day)
        } else {
            selectedWeekdays.remove(day)
        }
    }
}
