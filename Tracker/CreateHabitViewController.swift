import UIKit

protocol CreateHabitDelegate: AnyObject {
    func createHabitViewController(_ createHabitViewController: CreateHabitViewController,
                                   didCreate tracker: Tracker,
                                   in categoryTitle: String)
}

final class CreateHabitViewController: UIViewController,
                                       UITableViewDataSource,
                                       UITableViewDelegate,
                                       UITextFieldDelegate {
    
    weak var delegate: CreateHabitDelegate?
    
    private let side: CGFloat = 16
    private let listRowHeight: CGFloat = 75
    private let corner: CGFloat = 16
    
    private let grayText: UIColor   = UIColor.hex("#AEAFB4")
    private let cardGray: UIColor   = UIColor.hex("#E6E8EB", alpha: 0.3)
    private let titleBlack: UIColor = UIColor.hex("#1A1B22")
    private let createBlack: UIColor = UIColor.hex("#0E0E11")
    private let createDisabled: UIColor = UIColor.hex("#AEAFB4")
    private let outlineRed: UIColor = UIColor.hex("#F56B6C")
    
    private var selectedWeekdays: Set<Weekday> = []
    private var categoryTitle: String?
    private let maxNameLength: Int = 38
    
    private let titleLabel = UILabel()
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var nameStackView: UIStackView!
    private let nameField  = UITextField()
    private let limitLabel = UILabel()
    private let tableView  = UITableView(frame: .zero, style: .plain)
    private var tableHeightConstraint: NSLayoutConstraint?
    
    private var bottomBar: UIView!
    private var clearButton: UIButton!
    
    private lazy var cancelButton: UIButton = {
        let button = baseButton("Отменить", filled: false)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()
    private lazy var createButton: UIButton = {
        let button = baseButton("Создать", filled: true)
        button.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupHeader()
        buildNameField()
        setupTableAppearance()
        setupBottomButtons()
        setupScrollArea()
        
        setupKeyboardDismiss()
        updateCreateButtonState()
        
        DispatchQueue.main.async { [weak self] in self?.updateTableHeight() }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }
    
    private func setupHeader() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Новая привычка"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = titleBlack
        
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 38),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func buildNameField() {
        limitLabel.translatesAutoresizingMaskIntoConstraints = false
        limitLabel.text = "Ограничение 38 символов"
        limitLabel.textColor = UIColor.hex("#F56B6C")
        limitLabel.font = .systemFont(ofSize: 17, weight: .regular)
        limitLabel.textAlignment = .center
        limitLabel.isHidden = true
        
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.placeholder = "Введите название трекера"
        nameField.backgroundColor = cardGray
        nameField.borderStyle = .none
        nameField.layer.cornerRadius = corner
        nameField.layer.masksToBounds = true
        nameField.textColor = .label
        nameField.returnKeyType = .done
        nameField.clearButtonMode = .never
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: listRowHeight))
        nameField.leftView = leftPadding
        nameField.leftViewMode = .always
        
       
        let clearSize: CGFloat = 17
        let rightInset: CGFloat = 12
        let textGap: CGFloat  = 12
        let containerWidth = clearSize + rightInset + textGap
        let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: listRowHeight))
        rightContainer.isUserInteractionEnabled = true
        
        let clearNameButton = UIButton(type: .custom)
        clearNameButton.frame = CGRect(
            x: containerWidth - rightInset - clearSize,
            y: (listRowHeight - clearSize) / 2,
            width: clearSize,
            height: clearSize
        )
        if let img = UIImage(named: "xmark.circle")?.withRenderingMode(.alwaysOriginal) {
            clearNameButton.setImage(img, for: .normal)
        }
        clearNameButton.addTarget(self, action: #selector(clearName), for: .touchUpInside)
        clearNameButton.isHidden = true
        clearButton = clearNameButton
        
        rightContainer.addSubview(clearNameButton)
        nameField.rightView = rightContainer
        nameField.rightViewMode = .whileEditing
        
        nameStackView = UIStackView(arrangedSubviews: [nameField, limitLabel])
        nameStackView.axis = .vertical
        nameStackView.spacing = 8
        nameStackView.translatesAutoresizingMaskIntoConstraints = false
        nameField.heightAnchor.constraint(equalToConstant: listRowHeight).isActive = true
    }
    
    private func setupTableAppearance() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = cardGray
        tableView.isOpaque = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = listRowHeight
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
        
        tableView.layer.cornerRadius = corner
        tableView.layer.cornerCurve = .continuous
        tableView.layer.masksToBounds = true
        tableView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                         .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    
    private func setupScrollArea() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 24
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        contentStack.addArrangedSubview(nameStackView)
        contentStack.addArrangedSubview(tableView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -76)
        ])
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: side),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -side),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2*side)
        ])
        
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeightConstraint?.isActive = true
    }
    
    private func baseButton(_ title: String, filled: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = corner
        button.layer.masksToBounds = true
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        if filled {
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = createDisabled
        } else {
            button.backgroundColor = .clear
            button.layer.borderWidth = 1
            button.layer.borderColor = outlineRed.cgColor
            button.setTitleColor(outlineRed, for: .normal)
        }
        return button
    }
    
    private func setupBottomButtons() {
        bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.backgroundColor = .white
        view.addSubview(bottomBar)
        
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        let stack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        bottomBar.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            stack.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor)
        ])
    }
    
    private enum Row: Int, CaseIterable { case category, schedule }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Row(rawValue: indexPath.row)!
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        
        if #available(iOS 14.0, *) {
            cell.backgroundConfiguration = .clear()
        } else {
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
        }
        
        var config = cell.defaultContentConfiguration()
        config.textProperties.font = .systemFont(ofSize: 17, weight: .regular)
        config.textProperties.color = .label
        config.secondaryTextProperties.font = .systemFont(ofSize: 17, weight: .regular)
        config.secondaryTextProperties.color = grayText
        
        switch row {
        case .category:
            config.text = "Категория"
            config.secondaryText = (categoryTitle?.isEmpty == false) ? categoryTitle : nil
        case .schedule:
            config.text = "Расписание"
            config.secondaryText = selectedWeekdays.isEmpty ? nil : selectedWeekdays.ruListDescription
        }
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == Row.allCases.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Row(rawValue: indexPath.row) == .schedule else { return }
        
        let scheduleViewController = ScheduleViewController(selected: selectedWeekdays)
        scheduleViewController.onDone = { [weak self] days in
            self?.selectedWeekdays = days
            self?.updateCreateButtonState()
            self?.tableView.reloadRows(at: [IndexPath(row: Row.schedule.rawValue, section: 0)], with: .none)
            self?.updateTableHeight()
        }
        navigationController?.pushViewController(scheduleViewController, animated: true)
    }
    
    private func updateTableHeight() {
        tableView.layoutIfNeeded()
        let height = tableView.contentSize.height
        if abs((tableHeightConstraint?.constant ?? 0) - height) > 0.5 {
            tableHeightConstraint?.constant = height
            view.layoutIfNeeded()
        }
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingForce))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func endEditingForce() { view.endEditing(true) }
    @objc private func cancelTapped() { dismiss(animated: true) }
    
    @objc private func textChanged() {
        let count = nameField.text?.count ?? 0
        limitLabel.isHidden = count < maxNameLength
        clearButton.isHidden = count == 0
        updateCreateButtonState()
    }
    
    @objc private func clearName() {
        nameField.text = ""
        clearButton.isHidden = true         
        nameField.sendActions(for: .editingChanged)
    }
    
    @objc private func createTapped() {
        guard createButton.isEnabled else { return }
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        let color = UIColor.hex("#33B864")
        let emoji = "🙂"
        let schedule = selectedWeekdays
        
        let tracker = Tracker(name: name, color: color, emoji: emoji, schedule: schedule)
        let category = (categoryTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        ? (categoryTitle ?? "")
        : "Без категории"
        
        delegate?.createHabitViewController(self, didCreate: tracker, in: category)
        dismiss(animated: true)
    }
    
    private func updateCreateButtonState() {
        let nameValid = !(nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let daysValid = !selectedWeekdays.isEmpty
        let enabled = nameValid && daysValid
        
        createButton.isEnabled = enabled
        createButton.backgroundColor = enabled ? createBlack : createDisabled
        createButton.setTitleColor(.white, for: .normal)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard textField === nameField else { return true }
        let current = textField.text ?? ""
        guard let swiftRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: swiftRange, with: string)
        
        if updated.count <= maxNameLength {
            DispatchQueue.main.async { [weak self] in self?.textChanged() }
            return true
        }
        
        let remaining = max(0, maxNameLength - current.count)
        if remaining > 0 {
            let allowedPrefix = String(string.prefix(remaining))
            textField.text = current.replacingCharacters(in: swiftRange, with: allowedPrefix)
        }
        DispatchQueue.main.async { [weak self] in self?.textChanged() }
        return false
    }
}
