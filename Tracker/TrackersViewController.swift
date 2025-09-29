import UIKit

final class TrackersViewController: UIViewController,
                                    UICollectionViewDataSource,
                                    UICollectionViewDelegateFlowLayout,
                                    TrackerCellDelegate,
                                    CreateHabitDelegate {
    
    private enum Layout {
        static let side: CGFloat = 16
        static let headerTopInset: CGFloat = 0
        static let headerVerticalSpacing: CGFloat = 9
        static let searchHeight: CGFloat = 36
        static let searchRadius: CGFloat = 10
        static let searchPlaceholderFontSize: CGFloat = 17
        static let searchIconSize: CGFloat = 17
        static let searchLeftPadding: CGFloat = 12
        static let contentTopSpacing: CGFloat = 34
        static let interItemSpacing: CGFloat = 9
        static let lineSpacing: CGFloat = 9
        static let sectionTopInset: CGFloat = 0
        static let sectionBottomInset: CGFloat = 16
        static let sectionHeaderHeight: CGFloat = 44
        static let itemWidth: CGFloat = 167
        static let itemHeight: CGFloat = 148
    }
    
    private let storage = TrackerStorage.shared
    
    private var categories: [TrackerCategory] = []
    private var completedTrackers: Set<TrackerRecord> = []
    private var currentDate: Date = Date().startOfDay
    
    private let headerContainerView = UIView()
    private let headerStackView = UIStackView()
    private let topRowStackView = UIStackView()
    
    private let addTrackerButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = "Добавить"
        return button
    }()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        return picker
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.numberOfLines = 1
        return label
    }()
    
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = UIColor.hex("#F0F0F0")
        textField.layer.cornerRadius = Layout.searchRadius
        textField.layer.masksToBounds = true
        textField.textColor = .label
        textField.font = UIFont.systemFont(ofSize: Layout.searchPlaceholderFontSize, weight: .regular)
        
        let placeholder = NSAttributedString(
            string: "Поиск",
            attributes: [
                .foregroundColor: UIColor.hex("#AEAFB4"),
                .font: UIFont.systemFont(ofSize: Layout.searchPlaceholderFontSize, weight: .regular)
            ]
        )
        textField.attributedPlaceholder = placeholder
        
        let config = UIImage.SymbolConfiguration(pointSize: Layout.searchIconSize, weight: .regular)
        let image = UIImage(systemName: "magnifyingglass", withConfiguration: config)
        let iconView = UIImageView(image: image)
        iconView.tintColor = UIColor.hex("#AEAFB4")
        iconView.contentMode = .center
        
        let containerWidth: CGFloat = Layout.searchLeftPadding + 20
        let container = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: Layout.searchHeight))
        iconView.frame = CGRect(x: Layout.searchLeftPadding, y: 0, width: 20, height: Layout.searchHeight)
        container.addSubview(iconView)
        
        textField.leftView = container
        textField.leftViewMode = .always
        return textField
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: Layout.sectionTopInset,
                                           left: Layout.side,
                                           bottom: Layout.sectionBottomInset,
                                           right: Layout.side)
        layout.minimumInteritemSpacing = Layout.interItemSpacing
        layout.minimumLineSpacing = Layout.lineSpacing
        layout.headerReferenceSize = CGSize(width: 0, height: Layout.sectionHeaderHeight)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .white
        view.dataSource = self
        view.delegate = self
        view.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        view.register(TrackerSectionHeaderView.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                      withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier)
        return view
    }()
    
    private let emptyStateImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "dizzy"))
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.hex("#1A1B22")
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = ""

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: addTrackerButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
        
        setupHeaderFrame()
        setupCollectionAndEmptyState()
        
        addTrackerButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        if let loaded = storage.load() {
            self.categories = loaded.categories
            self.completedTrackers = loaded.completed
        }
        updateEmptyStateAndReload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
    }
    
    private func setupHeaderFrame() {
        [headerContainerView, headerStackView, topRowStackView,
         titleLabel, searchTextField]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        headerStackView.axis = .vertical
        headerStackView.alignment = .fill
        headerStackView.spacing = Layout.headerVerticalSpacing
        
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(searchTextField)
        
        view.addSubview(headerContainerView)
        headerContainerView.addSubview(headerStackView)
        
        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.side),
            headerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.side),
            
            headerStackView.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: Layout.headerTopInset),
            headerStackView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerStackView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            
            searchTextField.heightAnchor.constraint(equalToConstant: Layout.searchHeight)
        ])
    }
    
    private func setupCollectionAndEmptyState() {
        [collectionView, emptyStateImageView, emptyStateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: Layout.contentTopSpacing),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Layout.side),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Layout.side)
        ])
    }
    
    private func currentWeekday(for date: Date) -> Weekday? {
        let value = Calendar.current.component(.weekday, from: date)
        return Weekday(rawValue: value)
    }
    
    private var visibleCategories: [TrackerCategory] {
        let weekday = currentWeekday(for: currentDate)
        return categories.compactMap { category in
            let filtered = category.trackers.filter { tracker in
                guard let schedule = tracker.schedule else { return true }
                guard let weekday else { return false }
                return schedule.contains(weekday)
            }
            return filtered.isEmpty ? nil : TrackerCategory(title: category.title, trackers: filtered)
        }
    }
    
    private func updateEmptyStateAndReload() {
        let isEmpty = visibleCategories.isEmpty
        collectionView.isHidden = isEmpty
        emptyStateImageView.isHidden = !isEmpty
        emptyStateLabel.isHidden = !isEmpty
        collectionView.reloadData()
    }
    
    @objc private func dateChanged() {
        currentDate = datePicker.date.startOfDay
        updateEmptyStateAndReload()
    }
    
    @objc private func addButtonTapped() {
        let createHabitViewController = CreateHabitViewController()
        createHabitViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: createHabitViewController)
        navigationController.modalPresentationStyle = .pageSheet
        present(navigationController, animated: true)
    }
    
    private func isCompleted(_ trackerId: UUID, on date: Date) -> Bool {
        let record = TrackerRecord(trackerId: trackerId, date: date)
        return completedTrackers.contains(record)
    }
    
    private func complete(_ trackerId: UUID, on date: Date) {
        let record = TrackerRecord(trackerId: trackerId, date: date)
        completedTrackers.insert(record)
        persist()
    }
    
    private func uncomplete(_ trackerId: UUID, on date: Date) {
        let record = TrackerRecord(trackerId: trackerId, date: date)
        completedTrackers.remove(record)
        persist()
    }
    
    private func toggleComplete(_ trackerId: UUID, on date: Date) {
        if date.startOfDay > Date().startOfDay { return }
        if isCompleted(trackerId, on: date) { uncomplete(trackerId, on: date) }
        else { complete(trackerId, on: date) }
    }
    
    private func completionCount(for trackerId: UUID) -> Int {
        completedTrackers.filter { $0.trackerId == trackerId }.count
    }
    
    private func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        if let index = categories.firstIndex(where: { $0.title == categoryTitle }) {
            let existing = categories[index]
            let updated = TrackerCategory(title: existing.title, trackers: existing.trackers + [tracker])
            var temp = categories
            temp[index] = updated
            categories = temp
        } else {
            categories = categories + [TrackerCategory(title: categoryTitle, trackers: [tracker])]
        }
        persist()
    }
    
    private func deleteTracker(id: UUID) {
        for i in categories.indices {
            if let idx = categories[i].trackers.firstIndex(where: { $0.id == id }) {
                var trackers = categories[i].trackers
                trackers.remove(at: idx)
                categories[i] = TrackerCategory(title: categories[i].title, trackers: trackers)
                break
            }
        }
        completedTrackers = Set(completedTrackers.filter { $0.trackerId != id })
        persist()
    }
    
    func createHabitViewController(_ createHabitViewController: CreateHabitViewController,
                                   didCreate tracker: Tracker,
                                   in categoryTitle: String) {
        addTracker(tracker, to: categoryTitle)
        updateEmptyStateAndReload()
    }
    
    func trackerCellDidToggle(_ cell: TrackerCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let category = visibleCategories[indexPath.section]
        let tracker = category.trackers[indexPath.item]
        toggleComplete(tracker.id, on: currentDate)
        collectionView.reloadItems(at: [indexPath])
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else { return UICollectionViewCell() }
        
        let category = visibleCategories[indexPath.section]
        let tracker = category.trackers[indexPath.item]
        let isDone = isCompleted(tracker.id, on: currentDate)
        let total = completionCount(for: tracker.id)
        
        cell.configure(tracker: tracker, isCompleted: isDone, totalCompletions: total)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as! TrackerSectionHeaderView
            view.setTitle(visibleCategories[indexPath.section].title)
            return view
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width
        let totalSpacing = Layout.side * 2 + Layout.interItemSpacing
        let itemWidth = floor((availableWidth - totalSpacing) / 2.0)
        return CGSize(width: itemWidth, height: Layout.itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Layout.lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Layout.interItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        let id = tracker.id as NSCopying
        
        return UIContextMenuConfiguration(identifier: id, previewProvider: nil) { [weak self] _ in
            guard let self else { return UIMenu() }
            let delete = UIAction(title: "Удалить",
                                  image: UIImage(systemName: "trash"),
                                  attributes: .destructive) { _ in
                self.confirmAndDeleteTracker(id: tracker.id, at: indexPath)
            }
            return UIMenu(children: [delete])
        }
    }
    
    private func confirmAndDeleteTracker(id: UUID, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Удалить трекер?",
                                      message: "Действие нельзя отменить.",
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.performDeletion(id: id)
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        if let popoverPresentationController = alert.popoverPresentationController,
           let cell = collectionView.cellForItem(at: indexPath) {
            popoverPresentationController.sourceView = cell
            popoverPresentationController.sourceRect = cell.bounds
        }
        present(alert, animated: true)
    }
    
    private func performDeletion(id: UUID) {
        deleteTracker(id: id)
        updateEmptyStateAndReload()
    }
    
    private func persist() {
        storage.save(categories: categories, completed: completedTrackers)
    }
}
