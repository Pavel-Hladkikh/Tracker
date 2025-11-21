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
        
        static let filtersLeft: CGFloat = 131
        static let filtersRight: CGFloat = 130
        static let filtersBottom: CGFloat = 16
        static let filtersHeight: CGFloat = 50
    }
    
    private var currentFilter: TrackerFilter = .all
    
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
        button.accessibilityLabel = NSLocalizedString("add_button_accessibility", comment: "")
        return button
    }()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = .autoupdatingCurrent
        return picker
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("trackers_title", comment: "")
        label.textColor = .label
        label.font = .systemFont(ofSize: 34, weight: .bold)
        return label
    }()
    
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = Colors.searchBackground
        textField.layer.cornerRadius = Layout.searchRadius
        textField.layer.masksToBounds = true
        textField.textColor = Colors.searchText
        textField.font = .systemFont(ofSize: Layout.searchPlaceholderFontSize, weight: .regular)
        
        let placeholder = NSAttributedString(
            string: NSLocalizedString("search_placeholder", comment: ""),
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
        
        let leftPadding: CGFloat = 6
        let iconWidth: CGFloat = 20
        let containerWidth: CGFloat = Layout.searchLeftPadding + iconWidth + leftPadding
        let leftContainerView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: Layout.searchHeight))
        iconImageView.frame = CGRect(x: Layout.searchLeftPadding, y: 0, width: iconWidth, height: Layout.searchHeight)
        leftContainerView.addSubview(iconImageView)
        
        let spacer = UIView(frame: CGRect(x: Layout.searchLeftPadding + iconWidth, y: 0, width: leftPadding, height: Layout.searchHeight))
        leftContainerView.addSubview(spacer)
        
        textField.leftView = leftContainerView
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .search
        return textField
    }()
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0,
                                               left: Layout.side,
                                               bottom: Layout.sectionBottomInset,
                                               right: Layout.side)
        flowLayout.minimumInteritemSpacing = Layout.interItemSpacing
        flowLayout.minimumLineSpacing = Layout.lineSpacing
        flowLayout.headerReferenceSize = CGSize(width: 0, height: Layout.sectionHeaderHeight)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = Colors.base
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TrackerCell.self,
                                forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        collectionView.register(TrackerSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier)
        return collectionView
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "error"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("empty_state_title", comment: "")
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = Colors.baseInverse
        return label
    }()
    
    private let filtersButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(NSLocalizedString("filters_title", comment: "Фильтры"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        b.backgroundColor = UIColor.hex("#3772E7")
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 16
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.base
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        buildHeader()
        buildCollectionAndEmptyState()
        
        view.addSubview(filtersButton)
        NSLayoutConstraint.activate([
            filtersButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.filtersLeft),
            filtersButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.filtersRight),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.filtersBottom),
            filtersButton.heightAnchor.constraint(equalToConstant: Layout.filtersHeight)
        ])
        filtersButton.addTarget(self, action: #selector(filtersTapped), for: .touchUpInside)
        
        let bottomInset = Layout.filtersBottom + Layout.filtersHeight + 16
        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        
        addTrackerButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        searchTextField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        
        trackerStore.observer = self
        trackerStore.performFetch()
        rebuildSections()
        
        NotificationCenter.default.addObserver(
            forName: .categoryDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.trackerStore.performFetch()
            self?.rebuildSections()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.shared.track(event: .open, screen: .main)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AnalyticsService.shared.track(event: .close, screen: .main)
    }
    
    private func buildHeader() {
        [headerContainerView,
         headerStackView,
         topRowView,
         titleLabel,
         searchTextField].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
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
            headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                     constant: Layout.headerTop),
            headerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            headerStackView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerStackView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            
            topRowView.heightAnchor.constraint(equalToConstant: Layout.topRowHeight),
            
            addTrackerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                      constant: Layout.plusLeading),
            addTrackerButton.centerYAnchor.constraint(equalTo: topRowView.centerYAnchor),
            
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                 constant: -Layout.datePickerTrailing),
            datePicker.centerYAnchor.constraint(equalTo: topRowView.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                constant: Layout.side),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                 constant: -Layout.side),
            
            searchTextField.heightAnchor.constraint(equalToConstant: Layout.searchHeight),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                     constant: Layout.side),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                      constant: -Layout.side)
        ])
    }
    
    private func buildCollectionAndEmptyState() {
        [collectionView, emptyStateImageView, emptyStateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor,
                                                constant: Layout.contentTopSpacing),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor,
                                                 constant: 8)
        ])
    }
    
    private func rebuildSections() {
        let weekdayValue = Calendar.current.component(.weekday, from: currentDate)
        guard let weekday = Weekday(rawValue: weekdayValue) else {
            sections = []
            collectionView.reloadData()
            return
        }
        
        var grouped: [String: [Tracker]] = [:]
        
        let frcSections = trackerStore.numberOfSections()
        for s in 0..<frcSections {
            let rows = trackerStore.numberOfObjects(in: s)
            for r in 0..<rows {
                let indexPath = IndexPath(row: r, section: s)
                let tracker = trackerStore.object(at: indexPath)
                guard let schedule = tracker.schedule, schedule.contains(weekday) else { continue }
                let categoryTitle = trackerStore.categoryTitle(for: indexPath)
                grouped[categoryTitle, default: []].append(tracker)
            }
        }
        
        let totalForDay = grouped.values.reduce(0) { $0 + $1.count }
        filtersButton.isHidden = totalForDay == 0
        
        let query = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if !query.isEmpty {
            for (key, value) in grouped {
                grouped[key] = value.filter { $0.name.lowercased().contains(query) }
            }
        }
        
        let titles = grouped.keys.sorted()
        var built = titles.compactMap { title -> TrackerCategory? in
            guard let trackers = grouped[title], !trackers.isEmpty else { return nil }
            return TrackerCategory(title: title, trackers: trackers)
        }
        
        if currentFilter == .completed || currentFilter == .incomplete {
            built = built.map { cat in
                let filtered = cat.trackers.filter { t in
                    let done = isCompleted(t.id, on: currentDate)
                    return currentFilter == .completed ? done : !done
                }
                return TrackerCategory(title: cat.title, trackers: filtered)
            }.filter { !$0.trackers.isEmpty }
        }
        
        sections = built
        
        let isEmpty = sections.isEmpty
        let isSearchActive = !query.isEmpty
        let isFilterSpecial = currentFilter == .completed || currentFilter == .incomplete
        
        if isEmpty {
            collectionView.isHidden = true
            emptyStateImageView.isHidden = false
            emptyStateLabel.isHidden = false
            
            if isSearchActive || isFilterSpecial {
                emptyStateImageView.image = UIImage(named: "error")
                emptyStateLabel.text = NSLocalizedString("nothing_found_placeholder", comment: "")
            } else {
                emptyStateImageView.image = UIImage(named: "dizzy")
                emptyStateLabel.text = NSLocalizedString("empty_state_title", comment: "")
            }
        } else {
            collectionView.isHidden = false
            emptyStateImageView.isHidden = true
            emptyStateLabel.isHidden = true
        }
        
        collectionView.reloadData()
    }
    
    @objc private func dateChanged() {
        currentDate = datePicker.date.startOfDay
        rebuildSections()
    }
    
    @objc private func searchChanged() {
        let isEditing = !(searchTextField.text ?? "").isEmpty
        searchTextField.textColor = isEditing ? Colors.baseInverse : Colors.searchText
        rebuildSections()
    }
    
    @objc private func addButtonTapped() {
        AnalyticsService.shared.track(event: .click, screen: .main, item: .addTrack)
        
        let vc = CreateHabitViewController()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    @objc private func filtersTapped() {
        AnalyticsService.shared.track(event: .click, screen: .main, item: .filter)
        
        let vc = FiltersViewController(selected: currentFilter) { [weak self] chosen in
            guard let self = self else { return }
            switch chosen {
            case .all:
                self.currentFilter = .all
            case .today:
                self.currentDate = Date().startOfDay
                self.datePicker.date = self.currentDate
                self.currentFilter = .all
            case .completed:
                self.currentFilter = .completed
            case .incomplete:
                self.currentFilter = .incomplete
            }
            self.rebuildSections()
        }
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
    
    private func isCompleted(_ trackerId: UUID, on date: Date) -> Bool {
        recordStore.isTrackerCompleted(trackerId, on: date)
    }
    
    private func toggleComplete(_ trackerId: UUID, on date: Date) {
        let today = Date().startOfDay
        guard date <= today else { return }
        if isCompleted(trackerId, on: date) {
            recordStore.removeRecord(for: trackerId, on: date)
        } else {
            recordStore.addRecord(for: trackerId, on: date)
        }
    }
    
    private func deleteTracker(at indexPath: IndexPath) {
        let tracker = sections[indexPath.section].trackers[indexPath.item]
        trackerStore.delete(tracker: tracker)
        trackerStore.performFetch()
        rebuildSections()
    }
    
    private func confirmDeleteTracker(at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: NSLocalizedString("delete_tracker_confirm", comment: "Уверены что хотите удалить трекер?"),
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("delete_button_title", comment: "Удалить"),
            style: .destructive,
            handler: { [weak self] _ in
                AnalyticsService.shared.track(event: .click, screen: .main, item: .delete)
                self?.deleteTracker(at: indexPath)
            }
        ))
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("cancel_button_title", comment: "Отменить"),
            style: .cancel
        ))
        
        present(alert, animated: true)
    }
    
    private func presentEditFlow(for indexPath: IndexPath) {
        AnalyticsService.shared.track(event: .click, screen: .main, item: .edit)
        
        let tr = sections[indexPath.section].trackers[indexPath.item]
        let totalDays = recordStore.completedCount(for: tr.id)
        
        let vc = CreateHabitViewController()
        vc.delegate = self
        vc.enterEditMode(
            existing: tr,
            totalDays: totalDays,
            prefilledCategoryTitle: sections[indexPath.section].title
        )
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
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
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = sections[indexPath.section].trackers[indexPath.item]
        let done = isCompleted(tracker.id, on: currentDate)
        let total = recordStore.completedCount(for: tracker.id)
        
        cell.configure(tracker: tracker, isCompleted: done, totalCompletions: total)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! TrackerSectionHeaderView
        header.setTitle(sections[indexPath.section].title)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width
        let totalSpacing = Layout.side * 2 + Layout.interItemSpacing
        let itemWidth = floor((availableWidth - totalSpacing) / 2.0)
        return CGSize(width: itemWidth, height: Layout.itemHeight)
    }
    
    
    func trackerCellDidToggle(_ cell: TrackerCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let tracker = sections[indexPath.section].trackers[indexPath.item]
        
        AnalyticsService.shared.track(event: .click, screen: .main, item: .track)
        
        toggleComplete(tracker.id, on: currentDate)
        collectionView.reloadItems(at: [indexPath])
    }
    
    
    private func preview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard
            let indexPath = configuration.identifier as? IndexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell
        else { return nil }
        
        let params = UIPreviewParameters()
        let cardHeight: CGFloat = 90
        let rect = CGRect(x: 0, y: 0, width: cell.bounds.width, height: cardHeight)
        params.visiblePath = UIBezierPath(roundedRect: rect, cornerRadius: 16)
        
        return UITargetedPreview(view: cell, parameters: params)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { [weak self] _ in
            guard let self else { return UIMenu() }
            
            let edit = UIAction(title: NSLocalizedString("edit_button_title", comment: "")) { _ in
                self.presentEditFlow(for: indexPath)
            }
            
            let delete = UIAction(
                title: NSLocalizedString("delete_button_title", comment: ""),
                attributes: .destructive
            ) { _ in
                self.confirmDeleteTracker(at: indexPath)
            }
            
            return UIMenu(children: [edit, delete])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        preview(for: configuration)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        preview(for: configuration)
    }
    
    
    func createHabitViewController(_ createHabitViewController: CreateHabitViewController,
                                   didCreate tracker: Tracker,
                                   in categoryTitle: String) {
        let category = TrackerCategory(title: categoryTitle, trackers: [])
        trackerStore.upsert(tracker, in: category)
        dismiss(animated: true)
        trackerStore.performFetch()
        rebuildSections()
    }
}

extension TrackersViewController: TrackerStoreObserver {
    func storeDidUpdate(_ store: TrackerStore) {
        rebuildSections()
    }
}
