import UIKit

final class NewCategoryViewController: UIViewController {
    
    private var onSave: ((String) -> Void)?
    private let maxLength = 38
    private var isEditMode = false
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .black
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let textField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = UIColor.hex("#E6E8EB", alpha: 0.3)
        tf.layer.cornerRadius = 16
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.font = .systemFont(ofSize: 17)
        tf.textColor = .black
        tf.placeholder = "Введите название категории"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let clearButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let img = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)?
            .withRenderingMode(.alwaysTemplate)
        b.setImage(img, for: .normal)
        b.tintColor = UIColor(hex: "#AEAFB4")
        b.backgroundColor = .clear
        b.isHidden = true
        b.translatesAutoresizingMaskIntoConstraints = true
        return b
    }()
    
    private let warningLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.textColor = UIColor(hex: "#F56B6C")
        l.text = "Ограничение 38 символов"
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let doneButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Готово", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.backgroundColor = .black
        b.layer.cornerRadius = 16
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        addActions()
        updateDoneButtonState()
    }
    
    
    func configureForCreate(onSaved: @escaping (String) -> Void) {
        isEditMode = false
        titleLabel.text = "Новая категория"
        textField.text = ""
        onSave = onSaved
        clearButton.isHidden = true
        textField.rightView = nil
        textField.rightViewMode = .never
    }
    
    func configureForEdit(initialTitle: String, onSaved: @escaping (String) -> Void) {
        isEditMode = true
        titleLabel.text = "Редактирование категории"
        textField.text = initialTitle
        onSave = onSaved
        
        let trimmed = initialTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        clearButton.isHidden = trimmed.isEmpty
        
        
        let iconSize: CGFloat = 24
        let padding: CGFloat = 12
        let rightHeight: CGFloat = 75
        let rightWidth = iconSize + padding
        
        let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: rightWidth, height: rightHeight))
        clearButton.frame = CGRect(
            x: rightWidth - padding - iconSize,
            y: (rightHeight - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        rightContainer.addSubview(clearButton)
        textField.rightView = rightContainer
        textField.rightViewMode = .whileEditing
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(textField)
        view.addSubview(warningLabel)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 75),
            
            warningLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            warningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            doneButton.heightAnchor.constraint(equalToConstant: 60),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func addActions() {
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.addTarget(self, action: #selector(editingBegan), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingEnded), for: .editingDidEnd)
        
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }
    
    
    @objc private func editingBegan() {
        guard isEditMode else { return }
        let trimmed = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        clearButton.isHidden = trimmed.isEmpty
    }
    
    @objc private func editingEnded() {
        guard isEditMode else { return }
        clearButton.isHidden = true
    }
    
    @objc private func textDidChange() {
        let text = textField.text ?? ""
        if text.count > maxLength {
            textField.text = String(text.prefix(maxLength))
        }
        
        let currentCount = textField.text?.count ?? 0
        warningLabel.isHidden = currentCount < maxLength
        
        if isEditMode {
            let trimmed = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            clearButton.isHidden = !textField.isFirstResponder || trimmed.isEmpty
        }
        
        updateDoneButtonState()
    }
    
    @objc private func clearTapped() {
        textField.text = ""
        warningLabel.isHidden = true
        clearButton.isHidden = true
        updateDoneButtonState()
    }
    
    @objc private func doneTapped() {
        let trimmed = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maxLength else { return }
        
        onSave?(trimmed)
        dismiss(animated: true)
    }
    
    
    private func updateDoneButtonState() {
        let trimmed = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let enabled = !trimmed.isEmpty && trimmed.count <= maxLength
        
        doneButton.isEnabled = enabled
        doneButton.backgroundColor = enabled ? .black : UIColor(hex: "#AEAFB4")
    }
}
