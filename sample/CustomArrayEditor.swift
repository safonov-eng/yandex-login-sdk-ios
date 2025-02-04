import UIKit

class CustomArrayEditor: UIViewController {
    
    var valuesTable: CustomArrayTable?
    var completion: (([String]?) -> Void)?
    private var customValues: [String]? = nil
    
    convenience init(customValues: [String]? = nil, completion: @escaping ([String]?) -> Void) {
        self.init(nibName: nil, bundle: nil)
        self.completion = completion
        self.customValues = customValues

        self.modalPresentationStyle = .overFullScreen
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.completion = nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black.withAlphaComponent(0.3)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(contentView)
        contentView.backgroundColor = .white
        self.view.addConstraints([
            self.view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            self.view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            self.view.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: 44),
            self.view.heightAnchor.constraint(equalTo: contentView.heightAnchor, constant: 88)
        ])
        contentView.layer.cornerRadius = 22
        
        let table = CustomArrayTable()
        self.valuesTable = table
        table.translatesAutoresizingMaskIntoConstraints = false
        table.layer.cornerRadius = 22
        contentView.addSubview(table)
        contentView.addConstraints([
            contentView.centerXAnchor.constraint(equalTo: table.centerXAnchor),
            contentView.topAnchor.constraint(equalTo: table.topAnchor),
            contentView.widthAnchor.constraint(equalTo: table.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: table.heightAnchor, constant: 44),
        ])
        table.customValues = self.customValues ?? []
        
        let closeButton = UIButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.systemRed, for: .normal)
        contentView.addSubview(closeButton)
        self.view.addConstraints([
            contentView.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor),
            contentView.leftAnchor.constraint(equalTo: closeButton.leftAnchor),
            contentView.widthAnchor.constraint(equalTo: closeButton.widthAnchor, multiplier: 2),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        closeButton.addTarget(self, action: #selector(CustomValuesEditor.close), for: .primaryActionTriggered)
        
        let addButton = UIButton()
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add", for: .normal)
        addButton.setTitleColor(.systemBlue, for: .normal)
        contentView.addSubview(addButton)
        self.view.addConstraints([
            contentView.bottomAnchor.constraint(equalTo: addButton.bottomAnchor),
            contentView.rightAnchor.constraint(equalTo: addButton.rightAnchor),
            contentView.widthAnchor.constraint(equalTo: addButton.widthAnchor, multiplier: 2),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        addButton.addTarget(self, action: #selector(CustomArrayEditor.addValue), for: .primaryActionTriggered)
    }
    
    @objc
    func addValue() {
        let alert = UIAlertController(title: "Add value", message: "Any symbols can be used", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.tag = 1
            textField.text = "Value"
        }

        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak alert, weak self] (_) in
            if let valueTextField = alert?.textFields?[0], valueTextField.tag == 1, let value = valueTextField.text {
                self?.valuesTable?.customValues.append(value)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    @objc
    func close() {
        if let customValues = self.valuesTable?.customValues, !customValues.isEmpty {
            self.customValues = customValues
        } else {
            self.customValues = nil
        }
        self.completion?(self.customValues)

        DispatchQueue.main.async { [weak self] in
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
        }
    }
}

class CustomArrayTable: UITableView, UITableViewDataSource {
    class Cell: UITableViewCell {
        static let kReuseIdentifier = "valueCell"
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        }
        init() {
            super.init(style: .subtitle, reuseIdentifier: Cell.kReuseIdentifier)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func configureFor(value: String) {
            if #available(iOS 14.0, *) {
                var contentConfiguration = UIListContentConfiguration.subtitleCell()
                contentConfiguration.text = value
                self.contentConfiguration = contentConfiguration
            } else {
                self.textLabel?.text = value
            }
            
        }
    }

    var customValues: [String] = [] {
        didSet {
            self.reloadData()
        }
    }

    convenience init() {
        self.init(frame: .zero, style: .plain)
        self.dataSource = self
        self.register(Cell.self, forCellReuseIdentifier: Cell.kReuseIdentifier)
        self.allowsMultipleSelectionDuringEditing = false
    }

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
// MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return customValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.dequeueReusableCell(withIdentifier: Cell.kReuseIdentifier) as? Cell {
            let value = self.customValues[indexPath.row]
            cell.configureFor(value: value)
            return cell
        }

        let cell = Cell()

        let value = self.customValues[indexPath.row]
        cell.configureFor(value: value)
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.customValues.remove(at: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
