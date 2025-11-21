import UIKit

protocol CreateHabitDelegate: AnyObject {
    func createHabitViewController(
        _ createHabitViewController: CreateHabitViewController,
        didCreate tracker: Tracker,
        in categoryTitle: String
    )
}

final class CreateHabitViewController: UIViewController,
                                       UITableViewDataSource,
                                       UITableViewDelegate,
                                       UITextFieldDelegate,
                                       UICollectionViewDataSource,
                                       UICollectionViewDelegate,
                                       UICollectionViewDelegateFlowLayout {
    
    
    enum Mode {
        case create
        case edit(existing: Tracker, totalDays: Int)
    }
    
    private var mode: Mode = .create
    
    weak var delegate: CreateHabitDelegate?
    
    private let side: CGFloat = 16
    private let listRowHeight: CGFloat = 75
    private let corner: CGFloat = 16
    
    private let grayText = UIColor.hex("#AEAFB4")
    private let cardGray = Colors.cardStroke
    private let titleBlack = Colors.baseInverse
    private let createBlack = Colors.baseInverse
    private let createDisabled = UIColor.hex("#AEAFB4")
    private let outlineRed = UIColor.hex("#F56B6C")
    
    private var selectedWeekdays: Set<Weekday> = []
    private let savedCategoryTitleKey = "savedCategoryTitle"
    
    private var categoryTitle: String? {
        get { UserDefaults.standard.string(forKey: savedCategoryTitleKey) }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: savedCategoryTitleKey)
            } else {
                UserDefaults.standard.removeObject(forKey: savedCategoryTitleKey)
            }
        }
    }
    
    private let maxNameLength = 38
    
    private var selectedEmoji: String? { didSet { updateCreateButtonState() } }
    private var selectedColor: UIColor? { didSet { updateCreateButtonState() } }
    private var selectedEmojiIndexPath: IndexPath?
    private var selectedColorIndexPath: IndexPath?
    
    private let titleLabel = UILabel()
    private let daysLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        l.textColor = Colors.baseInverse
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var nameStackView = UIStackView()
    private let nameField = UITextField()
    private let limitLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var tableHeightConstraint: NSLayoutConstraint?
    
    private lazy var bottomBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = Colors.base
        return v
    }()
    
    private lazy var cancelButton: UIButton = {
        let b = baseButton(NSLocalizedString("cancel_button_title", comment: ""), filled: false)
        b.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var createButton: UIButton = {
        let b = baseButton(NSLocalizedString("create_button_title", comment: ""), filled: true)
        b.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var clearButton: UIButton = {
        let b = UIButton(type: .custom)
        let s: CGFloat = 17
        if let img = UIImage(systemName: "xmark.circle.fill")?
            .withTintColor(grayText, renderingMode: .alwaysOriginal) {
            b.setImage(img, for: .normal)
        }
        b.frame = CGRect(x: 0, y: 0, width: s, height: s)
        b.addTarget(self, action: #selector(clearName), for: .touchUpInside)
        b.isHidden = true
        return b
    }()
    
    private let emojiList = [
        "🙂","😻","🌺","🐶","❤️","😱",
        "😇","😡","🥶","🤔","🙌","🍔",
        "🥦","🏓","🥇","🎸","🏝","😪"
    ]
    
    private let colorList: [UIColor] = [
        UIColor.hex("#FD4C49"), UIColor.hex("#FF881E"), UIColor.hex("#007BFA"),
        UIColor.hex("#6E44FE"), UIColor.hex("#33CF69"), UIColor.hex("#E66DD4"),
        UIColor.hex("#F9D4D4"), UIColor.hex("#34A7FE"), UIColor.hex("#46E69D"),
        UIColor.hex("#35347C"), UIColor.hex("#FF674D"), UIColor.hex("#FF99CC"),
        UIColor.hex("#F6C48B"), UIColor.hex("#7994F5"), UIColor.hex("#832CF1"),
        UIColor.hex("#AD56DA"), UIColor.hex("#8D72E6"), UIColor.hex("#2FD058")
    ]
    
    private let emojiLabel = UILabel()
    private var emojiCollection: UICollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private var emojiHeightConstraint: NSLayoutConstraint?
    
    private let colorLabel = UILabel()
    private var colorCollection: UICollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private var colorHeightConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if case .create = mode {
            UserDefaults.standard.removeObject(forKey: savedCategoryTitleKey)
        }
        
        view.backgroundColor = Colors.base
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupHeader()
        buildNameField()
        setupTableAppearance()
        setupBottomButtons()
        setupScrollArea()
        setupEmojiSection()
        setupColorSection()
        setupKeyboardDismiss()
        updateCreateButtonState()
        
        DispatchQueue.main.async { [weak self] in
            self?.updateTableHeight()
            self?.updateCollectionHeights()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
        updateCollectionHeights()
    }
    
    private func setupHeader() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("new_habit_title", comment: "")
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = titleBlack
        
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 38),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func buildNameField() {
        limitLabel.translatesAutoresizingMaskIntoConstraints = false
        limitLabel.text = NSLocalizedString("name_limit_warning", comment: "")
        limitLabel.textColor = outlineRed
        limitLabel.font = UIFont.systemFont(ofSize: 17)
        limitLabel.textAlignment = .center
        limitLabel.isHidden = true
        
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.placeholder = NSLocalizedString("tracker_name_placeholder", comment: "")
        nameField.backgroundColor = cardGray
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
        
        let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: listRowHeight))
        rightContainer.addSubview(clearButton)
        clearButton.center = CGPoint(x: rightContainer.bounds.maxX - 20,
                                     y: rightContainer.bounds.midY)
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
        tableView.isScrollEnabled = false
        tableView.layer.cornerRadius = corner
        tableView.layer.cornerCurve = .continuous
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
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                               constant: -84),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                                                  constant: side),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                                                   constant: -side),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                                constant: -2 * side)
        ])
        
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeightConstraint?.isActive = true
    }
    
    private func baseButton(_ title: String, filled: Bool) -> UIButton {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        b.layer.cornerRadius = corner
        b.heightAnchor.constraint(equalToConstant: 60).isActive = true
        if filled {
            b.setTitleColor(Colors.base, for: .normal)
            b.backgroundColor = createDisabled
        } else {
            b.backgroundColor = .clear
            b.layer.borderWidth = 1
            b.layer.borderColor = outlineRed.cgColor
            b.setTitleColor(outlineRed, for: .normal)
        }
        return b
    }
    
    private func setupBottomButtons() {
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
    
    private func setupEmojiSection() {
        contentStack.setCustomSpacing(32, after: tableView)
        
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        
        emojiLabel.text = "Emoji"
        emojiLabel.font = UIFont.boldSystemFont(ofSize: 19)
        emojiLabel.textColor = titleBlack
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        header.addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            emojiLabel.topAnchor.constraint(equalTo: header.topAnchor),
            emojiLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor)
        ])
        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(0, after: header)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.estimatedItemSize = .zero
        emojiCollection.collectionViewLayout = layout
        
        emojiCollection.translatesAutoresizingMaskIntoConstraints = false
        emojiCollection.backgroundColor = .clear
        emojiCollection.isScrollEnabled = false
        emojiCollection.dataSource = self
        emojiCollection.delegate = self
        emojiCollection.allowsMultipleSelection = false
        emojiCollection.register(EmojiCell.self,
                                 forCellWithReuseIdentifier: "EmojiCell")
        
        contentStack.addArrangedSubview(emojiCollection)
        contentStack.setCustomSpacing(40, after: emojiCollection)
        
        emojiHeightConstraint = emojiCollection.heightAnchor.constraint(equalToConstant: 1)
        emojiHeightConstraint?.isActive = true
    }
    
    private func setupColorSection() {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        
        colorLabel.text = NSLocalizedString("color_title", comment: "")
        colorLabel.font = UIFont.boldSystemFont(ofSize: 19)
        colorLabel.textColor = titleBlack
        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        header.addSubview(colorLabel)
        NSLayoutConstraint.activate([
            colorLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            colorLabel.topAnchor.constraint(equalTo: header.topAnchor),
            colorLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor)
        ])
        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(0, after: header)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.estimatedItemSize = .zero
        colorCollection.collectionViewLayout = layout
        
        colorCollection.translatesAutoresizingMaskIntoConstraints = false
        colorCollection.backgroundColor = .clear
        colorCollection.isScrollEnabled = false
        colorCollection.dataSource = self
        colorCollection.delegate = self
        colorCollection.allowsMultipleSelection = false
        colorCollection.register(ColorCell.self,
                                 forCellWithReuseIdentifier: "ColorCell")
        
        contentStack.addArrangedSubview(colorCollection)
        
        colorHeightConstraint = colorCollection.heightAnchor.constraint(equalToConstant: 1)
        colorHeightConstraint?.isActive = true
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func textChanged() {
        let text = nameField.text ?? ""
        if text.count > maxNameLength {
            let limited = String(text.prefix(maxNameLength))
            nameField.text = limited
        }
        limitLabel.isHidden = (nameField.text?.count ?? 0) < maxNameLength
        clearButton.isHidden = (nameField.text?.isEmpty ?? true)
        updateCreateButtonState()
    }
    
    @objc private func clearName() {
        nameField.text = ""
        clearButton.isHidden = true
        nameField.sendActions(for: .editingChanged)
    }
    
    @objc private func createTapped() {
        guard createButton.isEnabled else { return }
        guard
            let emoji = selectedEmoji,
            let color = selectedColor
        else { return }
        
        let name = (nameField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let schedule = selectedWeekdays
        
        guard
            let categoryTitle = categoryTitle?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !categoryTitle.isEmpty
        else { return }
        
        let tracker: Tracker
        switch mode {
        case .create:
            tracker = Tracker(
                name: name,
                color: color,
                emoji: emoji,
                schedule: schedule
            )
        case .edit(let existing, _):
            tracker = Tracker(
                id: existing.id,
                name: name,
                color: color,
                emoji: emoji,
                schedule: schedule
            )
        }
        
        delegate?.createHabitViewController(
            self,
            didCreate: tracker,
            in: categoryTitle
        )
        
        dismiss(animated: true)
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(endEditingForce))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func endEditingForce() {
        view.endEditing(true)
    }
    
    private enum Row: Int, CaseIterable {
        case category
        case schedule
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = Row(rawValue: indexPath.row) else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell",
                                                 for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        
        var config = cell.defaultContentConfiguration()
        config.textProperties.font = UIFont.systemFont(ofSize: 17)
        config.textProperties.color = .label
        config.secondaryTextProperties.font = UIFont.systemFont(ofSize: 17)
        config.secondaryTextProperties.color = grayText
        
        switch row {
        case .category:
            config.text = NSLocalizedString("category_title", comment: "")
            config.secondaryText = categoryTitle?.isEmpty == false ? categoryTitle : nil
        case .schedule:
            config.text = NSLocalizedString("schedule_title", comment: "")
            config.secondaryText = selectedWeekdays.isEmpty
            ? nil
            : selectedWeekdays.ruListDescription
        }
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        let isLast = indexPath.row == Row.allCases.count - 1
        let rightInset: CGFloat = isLast ? tableView.bounds.width : 16
        cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: rightInset)
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        guard let row = Row(rawValue: indexPath.row) else { return }
        
        switch row {
        case .category:
            openCategoryPicker()
        case .schedule:
            let scheduleVC = ScheduleViewController(selected: selectedWeekdays)
            scheduleVC.onDone = { [weak self] days in
                self?.selectedWeekdays = days
                self?.updateCreateButtonState()
                self?.tableView.reloadRows(
                    at: [IndexPath(row: Row.schedule.rawValue, section: 0)],
                    with: .none
                )
                self?.updateTableHeight()
            }
            navigationController?.pushViewController(scheduleVC, animated: true)
        }
    }
    
    private func openCategoryPicker() {
        let vc = CategoriesViewController(preselectedCategoryTitle: categoryTitle)
        vc.modalPresentationStyle = .pageSheet
        
        vc.onCategoryPicked = { [weak self] category in
            guard let self else { return }
            self.categoryTitle = category.title
            self.tableView.reloadRows(
                at: [IndexPath(row: Row.category.rawValue, section: 0)],
                with: .none
            )
            self.updateCreateButtonState()
        }
        
        present(vc, animated: true)
    }
    
    private func updateTableHeight() {
        tableView.layoutIfNeeded()
        let height = tableView.contentSize.height
        if abs((tableHeightConstraint?.constant ?? 0) - height) > 0.5 {
            tableHeightConstraint?.constant = height
            view.layoutIfNeeded()
        }
    }
    
    private func updateCollectionHeights() {
        emojiCollection.layoutIfNeeded()
        let h1 = emojiCollection.collectionViewLayout
            .collectionViewContentSize.height
        if abs((emojiHeightConstraint?.constant ?? 0) - h1) > 0.5 {
            emojiHeightConstraint?.constant = h1
        }
        
        colorCollection.layoutIfNeeded()
        let h2 = colorCollection.collectionViewLayout
            .collectionViewContentSize.height
        if abs((colorHeightConstraint?.constant ?? 0) - h2) > 0.5 {
            colorHeightConstraint?.constant = h2
        }
        view.layoutIfNeeded()
    }
    
    private func updateCreateButtonState() {
        let nameValid = !(nameField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        let daysValid = !selectedWeekdays.isEmpty
        let emojiValid = selectedEmoji != nil
        let colorValid = selectedColor != nil
        let categoryValid = (categoryTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty == false)
        
        let enabled = nameValid && daysValid && emojiValid && colorValid && categoryValid
        
        createButton.isEnabled = enabled
        createButton.backgroundColor = enabled ? createBlack : createDisabled
        if enabled {
            createButton.setTitleColor(Colors.base, for: .normal)
        } else {
            createButton.setTitleColor(.white, for: .normal)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        5
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let topInset: CGFloat = 24
        let bottomInset: CGFloat = (collectionView === emojiCollection) ? 0 : 24
        return UIEdgeInsets(top: topInset, left: 2, bottom: bottomInset, right: 3)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 6
        let gaps: CGFloat = columns - 1
        let gap: CGFloat = 5
        let leftInset: CGFloat = 2
        let rightInset: CGFloat = 3
        
        let width = collectionView.bounds.width
        let available = width - leftInset - rightInset - gaps * gap
        let side = floor(available / columns)
        return CGSize(width: side, height: side)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if collectionView === emojiCollection {
            return emojiList.count
        } else if collectionView === colorCollection {
            return colorList.count
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === emojiCollection {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "EmojiCell",
                for: indexPath
            ) as! EmojiCell
            cell.configure(with: emojiList[indexPath.item])
            cell.isSelected = (indexPath == selectedEmojiIndexPath)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ColorCell",
                for: indexPath
            ) as! ColorCell
            cell.configure(with: colorList[indexPath.item])
            cell.isSelected = (indexPath == selectedColorIndexPath)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionView === emojiCollection {
            if selectedEmojiIndexPath == indexPath {
                collectionView.deselectItem(at: indexPath, animated: true)
                (collectionView.cellForItem(at: indexPath) as? EmojiCell)?
                    .isSelected = false
                selectedEmojiIndexPath = nil
                selectedEmoji = nil
                return false
            }
        } else if collectionView === colorCollection {
            if selectedColorIndexPath == indexPath {
                collectionView.deselectItem(at: indexPath, animated: true)
                (collectionView.cellForItem(at: indexPath) as? ColorCell)?
                    .isSelected = false
                selectedColorIndexPath = nil
                selectedColor = nil
                return false
            }
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        if collectionView === emojiCollection {
            if let prev = selectedEmojiIndexPath, prev != indexPath {
                collectionView.deselectItem(at: prev, animated: false)
                (collectionView.cellForItem(at: prev) as? EmojiCell)?
                    .isSelected = false
            }
            selectedEmojiIndexPath = indexPath
            selectedEmoji = emojiList[indexPath.item]
            (collectionView.cellForItem(at: indexPath) as? EmojiCell)?
                .isSelected = true
        } else if collectionView === colorCollection {
            if let prev = selectedColorIndexPath, prev != indexPath {
                collectionView.deselectItem(at: prev, animated: false)
                (collectionView.cellForItem(at: prev) as? ColorCell)?
                    .isSelected = false
            }
            selectedColorIndexPath = indexPath
            selectedColor = colorList[indexPath.item]
            (collectionView.cellForItem(at: indexPath) as? ColorCell)?
                .isSelected = true
        }
        updateCreateButtonState()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didDeselectItemAt indexPath: IndexPath) {
        if collectionView === emojiCollection {
            if selectedEmojiIndexPath == indexPath {
                selectedEmojiIndexPath = nil
            }
            if selectedEmoji == emojiList[indexPath.item] {
                selectedEmoji = nil
            }
            (collectionView.cellForItem(at: indexPath) as? EmojiCell)?
                .isSelected = false
        } else if collectionView === colorCollection {
            if selectedColorIndexPath == indexPath {
                selectedColorIndexPath = nil
            }
            if selectedColor == colorList[indexPath.item] {
                selectedColor = nil
            }
            (collectionView.cellForItem(at: indexPath) as? ColorCell)?
                .isSelected = false
        }
        updateCreateButtonState()
    }
    
    
    func enterEditMode(existing tr: Tracker, totalDays: Int, prefilledCategoryTitle: String?) {
        mode = .edit(existing: tr, totalDays: totalDays)
        
        loadViewIfNeeded()
        
        titleLabel.text = NSLocalizedString("edit_habit_title", comment: "")
        daysLabel.text = formatDays(totalDays)
        daysLabel.isHidden = false
        
        if !contentStack.arrangedSubviews.contains(daysLabel) {
            contentStack.insertArrangedSubview(daysLabel, at: 0)
            contentStack.setCustomSpacing(24, after: daysLabel)
        }
        
        nameField.text = tr.name
        selectedEmoji = tr.emoji
        selectedColor = tr.color
        categoryTitle = prefilledCategoryTitle
        selectedWeekdays = tr.schedule ?? []
        
        createButton.setTitle(NSLocalizedString("save_button_title", comment: ""), for: .normal)
        
        tableView.reloadData()
        emojiCollection.reloadData()
        colorCollection.reloadData()
        emojiCollection.layoutIfNeeded()
        colorCollection.layoutIfNeeded()
        
        if let emojiIndex = emojiList.firstIndex(of: tr.emoji) {
            selectedEmojiIndexPath = IndexPath(item: emojiIndex, section: 0)
        }
        
        if let colorIndex = colorList.firstIndex(where: {
            $0.toHexString() == tr.color.toHexString()
        }) {
            selectedColorIndexPath = IndexPath(item: colorIndex, section: 0)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if let ep = self.selectedEmojiIndexPath {
                self.emojiCollection.selectItem(at: ep, animated: false, scrollPosition: [])
                (self.emojiCollection.cellForItem(at: ep) as? EmojiCell)?.isSelected = true
            }
            
            if let cp = self.selectedColorIndexPath {
                self.colorCollection.selectItem(at: cp, animated: false, scrollPosition: [])
                (self.colorCollection.cellForItem(at: cp) as? ColorCell)?.isSelected = true
            }
        }
        
        updateCreateButtonState()
    }
    
    
    
    private func formatDays(_ n: Int) -> String {
        let tmpl = NSLocalizedString("days_format", comment: "pluralized days")
        return String.localizedStringWithFormat(tmpl, n)
    }
}

private final class EmojiCell: UICollectionViewCell {
    private let container = UIView()
    private let emojiLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            container.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            container.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        ])
        
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.font = UIFont.systemFont(ofSize: 32)
        emojiLabel.textAlignment = .center
        emojiLabel.numberOfLines = 1
        emojiLabel.lineBreakMode = .byClipping
        
        container.addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            emojiLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            emojiLabel.topAnchor.constraint(equalTo: container.topAnchor),
            emojiLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with emoji: String) {
        emojiLabel.text = emoji
        updateSelection()
    }
    
    private func updateSelection() {
        container.backgroundColor = isSelected ? UIColor.hex("#E6E8EB") : UIColor.clear
    }
    
    override var isSelected: Bool {
        didSet { updateSelection() }
    }
}

private final class ColorCell: UICollectionViewCell {
    private let container = UIView()
    private let colorView = UIView()
    private let ringLayer = CAShapeLayer()
    
    private let containerCorner: CGFloat = 8
    private let colorCorner: CGFloat = 8
    private let stroke: CGFloat = 3
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        contentView.clipsToBounds = false
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = Colors.base
        container.layer.cornerRadius = containerCorner
        container.layer.masksToBounds = true
        contentView.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            container.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            container.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        ])
        
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.layer.cornerRadius = colorCorner
        colorView.layer.masksToBounds = true
        container.addSubview(colorView)
        
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            colorView.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -12),
            colorView.heightAnchor.constraint(equalTo: container.heightAnchor, constant: -12)
        ])
        
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineWidth = stroke
        ringLayer.lineJoin = .miter
        ringLayer.lineCap = .butt
        container.layer.addSublayer(ringLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = stroke / 2
        ringLayer.frame = container.bounds
        ringLayer.path = UIBezierPath(
            roundedRect: container.bounds.insetBy(dx: inset, dy: inset),
            cornerRadius: 8
        ).cgPath
    }
    
    func configure(with color: UIColor) {
        colorView.backgroundColor = color
        updateSelection()
    }
    
    private func updateSelection() {
        guard let base = colorView.backgroundColor else { return }
        if isSelected {
            ringLayer.strokeColor = base.withAlphaComponent(0.3).cgColor
            ringLayer.opacity = 1
        } else {
            ringLayer.opacity = 0
        }
    }
    
    override var isSelected: Bool {
        didSet { updateSelection() }
    }
}
