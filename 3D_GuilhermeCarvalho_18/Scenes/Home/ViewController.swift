
import UIKit
import CoreData

class ViewController: UIViewController {
    private var list: [NSManagedObject] = []
    @IBOutlet weak var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.table.dataSource = self
        self.table.delegate = self
        
        let fake = FakeViewController()
        self.navigationController?.pushViewController(fake, animated: false)
        
        self.loadList()
        self.table.reloadData()
    }
    
    private func loadList() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PokemonEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "weight", ascending: false)]
        do {
            self.list = try context.fetch(fetchRequest)
        } catch {
            debugPrint("==> Erro ao recuperar dados do base CoreData")
        }
    }


    @IBAction func goToSearch(_ sender: Any) {
        let vc = SearchViewController()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ViewController: PokemonProtocol {
    func save(pokemon: Pokemon) {
        if self.list.first(where: { $0.value(forKey: "id") as? Int == pokemon.id }) != nil {
            return
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        if let entity = NSEntityDescription.entity(forEntityName: "PokemonEntity", in: context) {
            let pk = NSManagedObject(entity: entity, insertInto: context)
            
            pk.setValue(pokemon.id ?? 0, forKey: "id")
            pk.setValue(pokemon.sprites?.front_default ?? "", forKey: "frontImage")
            pk.setValue(pokemon.name ?? "", forKey: "name")
            pk.setValue(pokemon.abilities?[0].ability?.name ?? "", forKey: "abilities")
            pk.setValue(pokemon.forms?.count, forKey: "forms")
            pk.setValue(pokemon.height ?? 1, forKey: "height")
            pk.setValue(pokemon.weight ?? 1, forKey: "weight")
            pk.setValue(UUID().uuidString, forKey: "hashId")
        }
        do {
            try context.save()
        } catch {
            debugPrint("==> Falha ao gravar pokemon no CoreData")
        }
        self.reloadAll()
    }
    
    func delete(pokemon: NSManagedObject) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        do {
            context.delete(pokemon)
            try context.save()
        } catch {
            debugPrint("==> Erro ao tentar excluir pokemon")
        }
        self.reloadAll()
    }
    
    private func reloadAll() {
        self.loadList()
        self.table.reloadData()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? PokemonCell else {
            return UITableViewCell()
        }
        let item = self.list[indexPath.row]
        
        let url = item.value(forKey: "frontImage") as? String ?? ""
        let name = item.value(forKey: "name") as? String ?? ""
        let height = item.value(forKey: "height") as? Int ?? 0
        let weight = item.value(forKey: "weight") as? Int ?? 0
        let forms = item.value(forKey: "forms") as? Int ?? 0
        let id = item.value(forKey: "id") as? Int ?? 0
        
        let details = "Id: \(id). Formas: \(forms).\nPeso: \(weight). Altura: \(height)."
        
        cell.populate(title: name, description: details, url: url)
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120.0
        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "Delete", handler: { [weak self] _,_,_ in
            
            guard let validSelf = self else { return }
            let item = validSelf.list[indexPath.row]
            validSelf.delete(pokemon: item)
        })
        
        deleteAction.backgroundColor = .red
        deleteAction.image = .init(systemName: "trash", withConfiguration: nil)
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

