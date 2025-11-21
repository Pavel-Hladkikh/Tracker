import UIKit

final class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("filters_title", comment: "Filters")
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = Colors.baseInverse
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private var selected: TrackerFilter
    private let onSelect: (TrackerFilter) -> Void
    
    init(selected: TrackerFilter, onSelect: @escaping (TrackerFilter) -> Void) {
        self.selected = selected
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.base
        
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.rowHeight = 75
        tableView.separatorStyle = .singleLine
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.layer.cornerRadius = 16
        tableView.layer.masksToBounds = true
        
        
        tableView.tableFooterView = UIView()
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: CGFloat(4 * 75))
        ])
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        TrackerFilter.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = TrackerFilter.allCases[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = NSLocalizedString(item.titleKey, comment: "")
        cell.textLabel?.textColor = Colors.baseInverse
        cell.backgroundColor = Colors.cardStroke
        cell.selectionStyle = .none
        cell.accessoryType = (item == selected && item.showsCheckmark) ? .checkmark : .none
        cell.tintColor = UIColor.hex("#3772E7")
        
        
        if indexPath.row == TrackerFilter.allCases.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = TrackerFilter.allCases[indexPath.row]
        selected = item
        tableView.reloadData()
        dismiss(animated: true) { [onSelect] in onSelect(item) }
    }
}
