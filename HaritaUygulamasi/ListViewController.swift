//
//  ListViewController.swift
//  HaritaUygulamasi
//
//  Created by Abdulsamet Bakmaz on 11.09.2022.
//

import UIKit
import CoreData
//yapmamız gereken ilk şey list view ayarlarını yapmak classta kütüphaneleri çağırmak.
class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
    @IBOutlet weak var tableView: UITableView!
    
    
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    var secilenYerIsmi = ""
    var secilenYerId : UUID?
    override func viewDidLoad() {
        super.viewDidLoad()
        //core datadan veri çekeceğiz bunun içinde fetchRequest işlemi gerçekleştireceğiz
        
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(artiButtonTiklandi))//sağ üst tarafta bir + butonu için. Methoddaki action kısmı perform segue yapacağım kısım
        veriAl()
    }
    
    func veriAl(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")//requestimizi oluşturuyoruz
        request.returnsObjectsAsFaults = false
        do{
            //neyi deneyeceğiz context.fetch bize sonuçların olduğu bir dizi veriyordu ve any dizisi veriyordu. Biz NSManagedObject haline getirmek istiyorduk bu yüzden bir try catch işlemi yapacağız
            let sonuclar = try context.fetch(request)
            if sonuclar.count > 0{
                isimDizisi.removeAll(keepingCapacity: false) //diziye girmeden içini boşaltıp kapasite tutmamasını sağlıyoruz
                idDizisi.removeAll(keepingCapacity: false)

                for sonuc in sonuclar as! [NSManagedObject]{ //sonuclar any geliyor ve bunu NSmanagedObject olarak cast ettik
                    if let isim = sonuc.value(forKey: "isim") as? String{
                        isimDizisi.append(isim)
                    }
                    if let id = sonuc.value(forKey: "id") as? UUID{
                        idDizisi.append(id)
                    }
                }
                tableView.reloadData()//işimiz bittikten sonra tableViewımızı yeniliyoruz
            }
        }catch{
            print("hata")
        }
    }
    @objc func artiButtonTiklandi(){//tıklandığında yapılacak perform segue kodları
        //eğer hiç bir yere tıklanmazsa ve artı butonuna tıklanırsa perform segue yapmadan önce seçilen yer ismi boş gitsin ve boş ise yeni yer eklemeye geldiği belli olsun
        secilenYerIsmi = " "
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { //tableView'da herhangi bir rowa tıklandıysa ne yapacağız
        secilenYerIsmi = isimDizisi[indexPath.row]
        secilenYerId = idDizisi[indexPath.row] //böylece seçilen indexleri burada atamış oldum
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { //segue ye hazırlan
        if segue.identifier == "toMapsVC"{
            let destinationVC = segue.destination as! MapsViewController //gideceğim segueyi tanımladım
            destinationVC.secilenIsim = secilenYerIsmi
            destinationVC.secilenId = secilenYerId //böylece veri aktarımını gerçekleştirmiş olucam. Buradan sonra MapsViewController'a gidip seçilen isim boş değilse diye oluşturduğumuz ife gidiyorum
        }
    }
}
