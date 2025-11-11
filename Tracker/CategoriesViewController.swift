import UIKit

final class CategoriesViewController: UIViewController {
    
    
    var onCategoryPicked: ((TrackerCategory) -> Void)?
    
    
    private let viewModel: CategoriesViewModel
    
    
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Категория"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .black
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.rowHeight = 75
        tv.showsVerticalScrollIndicator = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let placeholderStack: UIStackView = {
        let imageView = UIImageView(image: UIImage(named: "dizzy"))
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "Привычки и события можно\nобъединить по смыслу"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.hex("#1A1B22")
        label.textAlignment = .center
        label.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        return stack
    }()
    
    private let addButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Добавить категорию", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.backgroundColor = .black
        b.layer.cornerRadius = 16
        b.layer.masksToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private var blurOverlay: UIVisualEffectView?
    private var contextMenuContainer: UIView?
    private var contextMenuAnchorSnapshot: UIView?
    private var activeMenuIndexPath: IndexPath?
    
    init(preselectedCategoryTitle: String? = nil) {
        self.viewModel = CategoriesViewModel(preselectedCategoryTitle: preselectedCategoryTitle)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        setupTable()
        bindViewModel()
        updatePlaceholderVisibility()
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(placeholderStack)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),
            
            addButton.heightAnchor.constraint(equalToConstant: 60),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            placeholderStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        addButton.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)
    }
    
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)
        
        tableView.layer.cornerRadius = 0
        tableView.layer.masksToBounds = false
        tableView.tableFooterView = UIView(frame: .zero)
        let longPress = UILongPressGestureRecognizer(target: self,
                                                     action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        tableView.addGestureRecognizer(longPress)
    }
    
    private func bindViewModel() {
        viewModel.onCategoriesUpdated = { [weak self] in
            guard let self else { return }
            self.tableView.reloadData()
            self.updatePlaceholderVisibility()
        }
        
        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
        
        viewModel.onCategoryPicked = { [weak self] category in
            guard let self else { return }
            self.onCategoryPicked?(category)
            self.dismiss(animated: true)
        }
    }
    
    private func updatePlaceholderVisibility() {
        let isEmpty = viewModel.countOfCategories == 0
        tableView.isHidden = isEmpty
        placeholderStack.isHidden = !isEmpty
    }
    
    @objc private func addCategoryTapped() {
        let vc = NewCategoryViewController()
        vc.modalPresentationStyle = .pageSheet
        vc.configureForCreate { [weak self] title in
            self?.viewModel.addCategory(title: title)
        }
        present(vc, animated: true)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              let cell = tableView.cellForRow(at: indexPath) else { return }
        
        showContextMenu(for: indexPath, anchorCell: cell)
    }
    
    private func showContextMenu(for indexPath: IndexPath, anchorCell: UITableViewCell) {
        hideContextMenu()
        
        guard
            let windowScene = view.window?.windowScene
                ?? (UIApplication.shared.connectedScenes.first as? UIWindowScene),
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else { return }
        
        activeMenuIndexPath = indexPath
        
        let cellFrameInWindow = anchorCell.convert(anchorCell.bounds, to: window)
        
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blur = UIVisualEffectView(effect: blurEffect)
        
        guard
            let windowScene = view.window?.windowScene
                ?? (UIApplication.shared.connectedScenes.first as? UIWindowScene),
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else {
            return
        }
        
        blur.frame = window.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(overlayTap))
        blur.addGestureRecognizer(tap)
        
        blur.alpha = 0
        window.addSubview(blur)
        blurOverlay = blur
        
        UIView.animate(withDuration: 0.2) {
            blur.alpha = 0.25
        }
        
        
        if let catCell = anchorCell as? CategoryCell {
            catCell.separatorInset = UIEdgeInsets(top: 0,
                                                  left: tableView.bounds.width,
                                                  bottom: 0,
                                                  right: 0)
        }
        
        if let snapshot = anchorCell.contentView.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = cellFrameInWindow
            snapshot.layer.cornerRadius = 16
            snapshot.layer.masksToBounds = true
            window.addSubview(snapshot)
            contextMenuAnchorSnapshot = snapshot
            anchorCell.isHidden = true
        }
        
        let menuWidth: CGFloat = 250
        let rowHeight: CGFloat = 48
        let topOffset: CGFloat = 12
        
        let menuX = cellFrameInWindow.minX
        let menuY = cellFrameInWindow.maxY + topOffset
        
        let menu = UIView(frame: CGRect(x: menuX,
                                        y: menuY,
                                        width: menuWidth,
                                        height: rowHeight * 2))
        menu.backgroundColor = UIColor.hex("#F2F2F2", alpha: 0.8)
        menu.layer.cornerRadius = 16
        menu.layer.masksToBounds = true
        window.addSubview(menu)
        contextMenuContainer = menu
        
        let editButton = UIButton(type: .system)
        var editConfig = UIButton.Configuration.plain()
        editConfig.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16)
        editConfig.titleAlignment = .leading
        editConfig.title = "Редактировать"
        editConfig.baseForegroundColor = UIColor.hex("#1A1B22")
        editButton.configuration = editConfig
        editButton.titleLabel?.font = .systemFont(ofSize: 17)
        editButton.tag = indexPath.row
        editButton.frame = CGRect(x: 0, y: 0, width: menuWidth, height: rowHeight)
        editButton.addTarget(self, action: #selector(editMenuTapped(_:)), for: .touchUpInside)
        menu.addSubview(editButton)
        
        let separator = UIView(frame: CGRect(x: 0,
                                             y: rowHeight - 0.5,
                                             width: menuWidth,
                                             height: 0.5))
        separator.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        menu.addSubview(separator)
        
        let deleteButton = UIButton(type: .system)
        var deleteConfig = UIButton.Configuration.plain()
        deleteConfig.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16)
        deleteConfig.titleAlignment = .leading
        deleteConfig.title = "Удалить"
        deleteConfig.baseForegroundColor = .systemRed
        deleteButton.configuration = deleteConfig
        deleteButton.titleLabel?.font = .systemFont(ofSize: 17)
        deleteButton.tag = indexPath.row
        deleteButton.frame = CGRect(x: 0, y: rowHeight, width: menuWidth, height: rowHeight)
        deleteButton.addTarget(self, action: #selector(deleteMenuTapped(_:)), for: .touchUpInside)
        menu.addSubview(deleteButton)
        
        UIView.animate(withDuration: 0.2) {
            blur.alpha = 1
        }
    }
    
    private func hideContextMenu() {
        guard blurOverlay != nil || contextMenuContainer != nil || contextMenuAnchorSnapshot != nil else {
            return
        }
        
        if let indexPath = activeMenuIndexPath,
           let cell = tableView.cellForRow(at: indexPath) {
            
            cell.isHidden = false
            
            let total = viewModel.countOfCategories
            if indexPath.row == total - 1 {
                
                cell.separatorInset = UIEdgeInsets(
                    top: 0,
                    left: tableView.bounds.width,
                    bottom: 0,
                    right: 0
                )
            } else {
                cell.separatorInset = UIEdgeInsets(
                    top: 0,
                    left: 16,
                    bottom: 0,
                    right: 16
                )
            }
        }
        activeMenuIndexPath = nil
        
        UIView.animate(withDuration: 0.2, animations: {
            self.blurOverlay?.alpha = 0
            self.contextMenuContainer?.alpha = 0
            self.contextMenuAnchorSnapshot?.alpha = 0
        }, completion: { _ in
            self.blurOverlay?.removeFromSuperview()
            self.contextMenuContainer?.removeFromSuperview()
            self.contextMenuAnchorSnapshot?.removeFromSuperview()
            self.blurOverlay = nil
            self.contextMenuContainer = nil
            self.contextMenuAnchorSnapshot = nil
        })
    }
    
    
    
    @objc private func overlayTap() {
        hideContextMenu()
    }
    
    @objc private func editMenuTapped(_ sender: UIButton) {
        let index = sender.tag
        hideContextMenu()
        showEditCategory(at: index)
    }
    
    @objc private func deleteMenuTapped(_ sender: UIButton) {
        let index = sender.tag
        hideContextMenu()
        confirmDeleteCategory(at: index)
    }
    
    private func showEditCategory(at index: Int) {
        guard let old = viewModel.category(at: index) else { return }
        
        let vc = NewCategoryViewController()
        vc.modalPresentationStyle = .pageSheet
        vc.configureForEdit(initialTitle: old.title) { [weak self] newTitle in
            self?.viewModel.renameCategory(at: index, newTitle: newTitle)
        }
        present(vc, animated: true)
    }
    
    private func confirmDeleteCategory(at index: Int) {
        guard viewModel.category(at: index) != nil else { return }
        
        let alert = UIAlertController(
            title: "Эта категория точно не нужна?",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let delete = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(at: index)
        }
        let cancel = UIAlertAction(title: "Отменить", style: .cancel)
        
        alert.addAction(delete)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension CategoriesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        viewModel.countOfCategories
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.reuseIdentifier,
            for: indexPath
        ) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let title = viewModel.title(at: indexPath.row)
        let isSelected = viewModel.isSelectedCategory(at: indexPath.row)
        cell.configure(title: title, isSelected: isSelected)
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell
    }
}

extension CategoriesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        viewModel.userSelectedCategory(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        guard let catCell = cell as? CategoryCell else { return }
        
        let total = viewModel.countOfCategories
        catCell.updateCorners(for: indexPath.row, totalRows: total)
        
        if indexPath.row == total - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0,
                                               left: tableView.bounds.width,
                                               bottom: 0,
                                               right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0,
                                               left: 16,
                                               bottom: 0,
                                               right: 16)
        }
    }
}
