import UIKit

final class TrackersViewController: UIViewController,
                                    UICollectionViewDataSource,
                                    UICollectionViewDelegateFlowLayout,
                                    TrackerCellDelegate,
                                    CreateHabitDelegate {

    private enum Layout {
        static let side: CGFloat = 16
        static let headerTop: CGFloat = 0
        static let headerVerticalSpacing: CGFloat = 9
        static let contentTopSpacing: CGFloat = 24
        static let plusLeading: CGFloat = 18
        static let datePickerTrailing: CGFloat = 16
        static let topRowHeight: CGFloat = 44
        static let searchHeight: CGFloat = 36
        static let searchRadius: CGFloat = 10
        static let searchPlaceholderFontSize: CGFloat = 17
        static let searchIconSize: CGFloat = 17
        static let searchLeftPadding: CGFloat = 12
        static let interItemSpacing: CGFloat = 9
        static let lineSpacing: CGFloat = 9
        static let sectionBottomInset: CGFloat = 16
        static let sectionHeaderHeight: CGFloat = 48
        static let itemHeight: CGFloat = 148
    }

    private let trackerStore = TrackerStore()
    private let recordStore = TrackerRecordStore()

    private var currentDate: Date = Date().startOfDay
    private var sections: [TrackerCategory] = []

    private let headerContainerView = UIView()
    private let headerStackView = UIStackView()
    private let topRowView = UIView()

    private let addTrackerButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: configuration), for: .normal)
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
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.numberOfLines = 1
        return label
    }()

    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = UIColor.hex("#F0F0F0")
        textField.layer.cornerRadius = Layout.searchRadius
        textField.layer.masksToBounds = true
        textField.textColor = .label
        textField.font = .systemFont(ofSize: Layout.searchPlaceholderFontSize, weight: .regular)

        let placeholder = NSAttributedString(
            string: "Поиск",
            attributes: [
                .foregroundColor: UIColor.hex("#AEAFB4"),
                .font: UIFont.systemFont(ofSize: Layout.searchPlaceholderFontSize, weight: .regular)
            ]
        )
        textField.attributedPlaceholder = placeholder

        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: Layout.searchIconSize, weight: .regular)
        let magnifierImage = UIImage(systemName: "magnifyingglass", withConfiguration: symbolConfiguration)
        let iconImageView = UIImageView(image: magnifierImage)
        iconImageView.tintColor = UIColor.hex("#AEAFB4")
        iconImageView.contentMode = .center

        let containerWidth: CGFloat = Layout.searchLeftPadding + 20
        let leftContainerView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: Layout.searchHeight))
        iconImageView.frame = CGRect(x: Layout.searchLeftPadding, y: 0, width: 20, height: Layout.searchHeight)
        leftContainerView.addSubview(iconImageView)

        textField.leftView = leftContainerView
        textField.leftViewMode = .always
        return textField
    }()

    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: Layout.side, bottom: Layout.sectionBottomInset, right: Layout.side)
        flowLayout.minimumInteritemSpacing = Layout.interItemSpacing
        flowLayout.minimumLineSpacing = Layout.lineSpacing
        flowLayout.headerReferenceSize = CGSize(width: 0, height: Layout.sectionHeaderHeight)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        collectionView.register(TrackerSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier)
        return collectionView
    }()

    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "dizzy"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.hex("#1A1B22")
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        buildHeader()
        buildCollectionAndEmptyState()

        addTrackerButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        trackerStore.observer = self
        recordStore.observer = self
        try? trackerStore.performFetch()
        try? recordStore.performFetch()
        rebuildSections()
    }

    deinit {
        if trackerStore.observer === self { trackerStore.observer = nil }
        if recordStore.observer === self { recordStore.observer = nil }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
    }

    private func buildHeader() {
        [headerContainerView, headerStackView, topRowView, titleLabel, searchTextField].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        [addTrackerButton, datePicker].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        headerStackView.axis = .vertical
        headerStackView.alignment = .fill
        headerStackView.spacing = Layout.headerVerticalSpacing

        view.addSubview(headerContainerView)
        headerContainerView.addSubview(headerStackView)

        headerStackView.addArrangedSubview(topRowView)
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(searchTextField)

        topRowView.addSubview(addTrackerButton)
        topRowView.addSubview(datePicker)

        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.headerTop),
            headerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerStackView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerStackView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),

            topRowView.heightAnchor.constraint(equalToConstant: Layout.topRowHeight),

            addTrackerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.plusLeading),
            addTrackerButton.centerYAnchor.constraint(equalTo: topRowView.centerYAnchor),

            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.datePickerTrailing),
            datePicker.centerYAnchor.constraint(equalTo: topRowView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.side),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.side),

            searchTextField.heightAnchor.constraint(equalToConstant: Layout.searchHeight),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.side),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.side),
        ])
    }

    private func buildCollectionAndEmptyState() {
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

    private func rebuildSections() {
        var builtSections: [TrackerCategory] = []
        let weekdayValue = Calendar.current.component(.weekday, from: currentDate)
        let currentWeekday = Weekday(rawValue: weekdayValue)

        let sectionCount = trackerStore.numberOfSections()
        for sectionIndex in 0..<sectionCount {
            let storedObjects = trackerStore.objects(inSection: sectionIndex)
            let trackers = storedObjects
                .map { trackerStore.mapToModel($0) }
                .filter { tracker in
                    guard let schedule = tracker.schedule, let weekday = currentWeekday else { return false }
                    return schedule.contains(weekday)
                }
            if !trackers.isEmpty {
                let sectionTitle = trackerStore.titleForSection(sectionIndex)
                builtSections.append(TrackerCategory(title: sectionTitle, trackers: trackers))
            }
        }

        sections = builtSections
        let isEmpty = sections.isEmpty
        collectionView.isHidden = isEmpty
        emptyStateImageView.isHidden = !isEmpty
        emptyStateLabel.isHidden = !isEmpty
        collectionView.reloadData()
    }

    @objc private func dateChanged() {
        currentDate = datePicker.date.startOfDay
        rebuildSections()
    }

    @objc private func addButtonTapped() {
        let createHabitViewController = CreateHabitViewController()
        createHabitViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: createHabitViewController)
        navigationController.modalPresentationStyle = .pageSheet
        present(navigationController, animated: true)
    }

    private func isCompleted(_ trackerId: UUID, on date: Date) -> Bool {
        (try? recordStore.isCompleted(trackerId: trackerId, on: date)) ?? false
    }

    private func toggleComplete(_ trackerId: UUID, on date: Date) {
        let record = TrackerRecord(trackerId: trackerId, date: date)
        if isCompleted(trackerId, on: date) {
            _ = try? recordStore.remove(record)
        } else {
            _ = try? recordStore.add(record)
        }
    }

    func createHabitViewController(_ createHabitViewController: CreateHabitViewController,
                                   didCreate tracker: Tracker,
                                   in categoryTitle: String) {
        try? trackerStore.upsert(tracker, in: categoryTitle)
        dismiss(animated: true)
        rebuildSections()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { sections.count }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].trackers.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else { return UICollectionViewCell() }

        let tracker = sections[indexPath.section].trackers[indexPath.item]
        let isDone = isCompleted(tracker.id, on: currentDate)
        let totalCompletions = (try? recordStore.completionCount(trackerId: tracker.id)) ?? 0

        cell.configure(tracker: tracker, isCompleted: isDone, totalCompletions: totalCompletions)
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
        let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! TrackerSectionHeaderView
        headerView.setTitle(sections[indexPath.section].title)
        return headerView
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
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat { Layout.lineSpacing }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { Layout.interItemSpacing }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        let tracker = sections[indexPath.section].trackers[indexPath.item]
        let identifier = tracker.id as NSCopying
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { [weak self] _ in
            guard let self else { return UIMenu() }
            let deleteAction = UIAction(title: "Удалить", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.confirmAndDeleteTracker(id: tracker.id, at: indexPath)
            }
            return UIMenu(children: [deleteAction])
        }
    }

    private func confirmAndDeleteTracker(id: UUID, at indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Удалить трекер?",
                                                message: "Действие нельзя отменить.",
                                                preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.performDeletion(id: id)
        })
        alertController.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        if let popover = alertController.popoverPresentationController,
           let cell = collectionView.cellForItem(at: indexPath) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        present(alertController, animated: true)
    }

    private func performDeletion(id: UUID) {
        try? recordStore.removeAll(for: id)
        try? trackerStore.delete(id: id)
        rebuildSections()
    }

    func trackerCellDidToggle(_ cell: TrackerCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let tracker = sections[indexPath.section].trackers[indexPath.item]
        toggleComplete(tracker.id, on: currentDate)
        collectionView.reloadItems(at: [indexPath])
    }
}

extension TrackersViewController: TrackerStoreObserver, TrackerRecordStoreObserver {

    func storeWillChangeContent() {}

    func storeDidChangeSection(at sectionIndex: Int, for type: StoreChangeType) {}

    func storeDidChangeItem(at indexPath: IndexPath?, for type: StoreChangeType, newIndexPath: IndexPath?) {
        rebuildSections()
    }

    func storeDidChangeContent() {
        rebuildSections()
        collectionView.reloadData()
    }
}
