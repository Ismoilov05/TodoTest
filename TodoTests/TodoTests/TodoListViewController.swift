//
//  ViewController.swift
//  TodoTests
//
//  Created by Muhammad on 26/02/25.
//

import UIKit

struct Todo: Codable {
    let id: Int
    let title: String
    let completed: Bool
    let userId: Int
    var user: User?
}

struct User: Codable {
    let id: Int
    let name: String
}

class APIService {
    static let shared = APIService()
    private let todoURL = URL(string: "https://jsonplaceholder.typicode.com/todos")!
    private let userURL = URL(string: "https://jsonplaceholder.typicode.com/users")!
    
    func fetchTodos(completion: @escaping ([Todo]?) -> Void) {
        URLSession.shared.dataTask(with: todoURL) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let todos = try? JSONDecoder().decode([Todo].self, from: data)
            completion(todos)
        }.resume()
    }
    
    func fetchUsers(completion: @escaping ([User]?) -> Void) {
        URLSession.shared.dataTask(with: userURL) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let users = try? JSONDecoder().decode([User].self, from: data)
            completion(users)
        }.resume()
    }
}

class TodoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private var todos: [Todo] = []
    private var filteredTodos: [Todo] = []
    private var users: [User] = []
    private var currentPage = 0
    private let pageSize = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        fetchData()
    }
    
    private func setupUI() {
        searchBar.delegate = self
        searchBar.placeholder = "Search by title or user"
        view.addSubview(searchBar)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchData() {
        APIService.shared.fetchUsers { [weak self] users in
            guard let self = self, let users = users else { return }
            self.users = users
            self.fetchTodos()
        }
    }
    
    private func fetchTodos() {
        APIService.shared.fetchTodos { [weak self] todos in
            guard let self = self, let todos = todos else { return }
            self.todos = todos.map { todo in
                var updatedTodo = todo
                updatedTodo.user = self.users.first { $0.id == todo.userId }
                return updatedTodo
            }
            self.filteredTodos = Array(self.todos.prefix(self.pageSize))
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTodos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let todo = filteredTodos[indexPath.row]
        cell.textLabel?.text = "\(todo.title) - \(todo.user?.name ?? "Unknown")"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = TodoDetailViewController(todo: filteredTodos[indexPath.row])
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredTodos = Array(todos.prefix(pageSize * (currentPage + 1)))
        } else {
            filteredTodos = todos.filter { $0.title.lowercased().contains(searchText.lowercased()) || (($0.user?.name.lowercased().contains(searchText.lowercased())) != nil) }
        }
        tableView.reloadData()
    }
}

class TodoDetailViewController: UIViewController {
    private let todo: Todo
    
    init(todo: Todo) {
        self.todo = todo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Todo Details"
        let label = UILabel()
        label.text = "Title: \(todo.title)\nUser: \(todo.user?.name ?? "Unknown")\nCompleted: \(todo.completed)"
        label.numberOfLines = 0
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
