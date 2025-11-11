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
        collectionView.backgroundColor = .white
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
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        collectionView.addGestureRecognizer(longPress)
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
        
        let query = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if !query.isEmpty {
            for (key, value) in grouped {
                grouped[key] = value.filter { $0.name.lowercased().contains(query) }
            }
        }
        
        let titles = grouped.keys.sorted()
        sections = titles.compactMap { title in
            guard let trackers = grouped[title], !trackers.isEmpty else { return nil }
            return TrackerCategory(title: title, trackers: trackers)
        }
        
        let isEmpty = sections.isEmpty
        collectionView.isHidden = isEmpty
        emptyStateImageView.isHidden = !isEmpty
        emptyStateLabel.isHidden = !isEmpty
        
        collectionView.reloadData()
    }
    
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        showContextMenu(for: indexPath)
    }
    
    private func showContextMenu(for indexPath: IndexPath) {
        let tracker = sections[indexPath.section].trackers[indexPath.item]
        
        let alert = UIAlertController(title: "Удалить трекер «\(tracker.name)»?",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.deleteTracker(at: indexPath)
        }
        
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func deleteTracker(at indexPath: IndexPath) {
        let tracker = sections[indexPath.section].trackers[indexPath.item]
        trackerStore.delete(tracker: tracker)
        trackerStore.performFetch()
        rebuildSections()
    }
    
    @objc private func dateChanged() {
        currentDate = datePicker.date.startOfDay
        rebuildSections()
    }
    
    @objc private func searchChanged() {
        rebuildSections()
    }
    
    @objc private func addButtonTapped() {
        let vc = CreateHabitViewController()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
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
    
    func createHabitViewController(_ createHabitViewController: CreateHabitViewController,
                                   didCreate tracker: Tracker,
                                   in categoryTitle: String) {
        let category = TrackerCategory(title: categoryTitle, trackers: [])
        trackerStore.upsert(tracker, in: category)
        dismiss(animated: true)
        trackerStore.performFetch()
        rebuildSections()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { sections.count }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        sections[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else { return UICollectionViewCell() }
        
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
        toggleComplete(tracker.id, on: currentDate)
        collectionView.reloadItems(at: [indexPath])
    }
}

extension TrackersViewController: TrackerStoreObserver {
    func storeDidUpdate(_ store: TrackerStore) {
        rebuildSections()
    }
}
