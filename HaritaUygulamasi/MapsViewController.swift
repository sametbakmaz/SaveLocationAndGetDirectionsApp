//
//  ViewController.swift
//  HaritaUygulamasi
//
//  Created by Abdulsamet Bakmaz on 9.09.2022.
//

import UIKit
import MapKit//harita için gerekli import
import CoreLocation//kullanıcının lokasyonunu almak için gerekli import
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var notTextField: UITextField!
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView! // ilk başta hata verir mapkit'i import etmen gerek
    
    var locationManager = CLLocationManager()//konumla ilgili yönetim için CLLocationManager sınıfından değişken yarattık
    var secilenLatitude = Double()
    var secilenLongitude = Double()//enlem ve boylamı alabilmemiz için double bir değişken oluşturmamız gerekiyordu ki core datada double oluşturduğumuz için setlemeyi böyle bekliyor
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self //Haritayı aldık ekranda gösterdik
        locationManager.delegate = self //konum yöneticisinin de delegasyonunu viewController'a verdik, CLocationManageri classa ekledik
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //konumun keskinliği yani doğruluk payı nasıl olsun (kcl yazıp diğer seçeneklere bakabilirsin bir çok seçeneği mevcut km vs.)
        locationManager.requestWhenInUseAuthorization() //konum için izin isteği, sadece uygulama kullanılırken izin verilsin !!önemli - info plist'e gidip information propertyList'e yeni bir tane eklememiz gerek. Privacy - Location When in use description u eklemeliyiz. Yani kullanıcı uygulamasını kullanırken konum izni istenmeli
        locationManager.startUpdatingLocation() //konumu güncellemeye başla
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer:)))//jest algılayıcıları kullanarak uzun tıklanan yere pin koyma işaret koyma fonksiyonu -> uzun tıklama yaptığımız anlaması için longPresGestureRecognizer kullandık
        gestureRecognizer.minimumPressDuration = 3//minimum basılı tutma, basma süresi
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    @objc func konumSec(gestureRecognizer : UILongPressGestureRecognizer){//oluşturduğum gestureRecognizere fonksiyonda ulaşmam gerek
        if gestureRecognizer.state == .began{ //jest algılayıcının durumunu belirlemek için yazdık. Başladı mı kontrolünü koyduk
            let dokunulanNokta = gestureRecognizer.location(in: mapView)//kullanıcının uzun tıkladığı konumu parametre olarak hesaplayabilmek için gestureRecognizer'ı burada kullanmam gerekti. Aslonda location fonksiyonu benim işimi görüyor
            let dokunulanKordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)//dokunulan noktadayı kordinata çevirme işlemi yapmamız gerekiyor
            
            secilenLatitude = dokunulanKordinat.latitude
            secilenLongitude = dokunulanKordinat.longitude
            
            let annotation = MKPointAnnotation() //haritada anotasyon koymak için gerekli fonksiyon
            annotation.coordinate = dokunulanKordinat //koyduğumuz anotasyona aldığımzı koordinatı vererek doğrluğunu sağlıyorum
            annotation.title = isimTextField.text //Anotasyona başlık veriyoruz
            annotation.subtitle = notTextField.text
            mapView.addAnnotation(annotation)
        }
        
        
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //konumlar güncellendi fonksiyonu ve [CLLocation] bana tek tek güncellenen konumları veriyor yani bu dönen konumu benim alıp işlemem gerek yani locations[0]' ı çağırdığımda kullanabilirim
        //print(locations[0].coordinate.latitude) //enlem
        //print(locations[0].coordinate.longitude) //boylam
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)//bizden delta bekliyor ilk 0.1 0.1 vererek denedik 0.9-0.9 verseydik zoom out açılacaktı konum yani uzaktan yaklaştırılmamış hali
        let location = CLLocationCoordinate2DMake(locations[0].coordinate.latitude,  locations[0].coordinate.longitude)//enlemi ve boylamı alıp location değişkenimde tutuyoruz. Haritada konumumuza gitmemiz için gerekli
        let region = MKCoordinateRegion(center: location, span: span)//Center nereye merkez alıp konumlanacağı yani yukarda oluşturduğumuz location.
        mapView.setRegion(region, animated: true) //bulunduğun bölge öncesinde regionu oluşturmam gerek
        
        //locationManager() fonksiyonunda kısaca her güncelleme olduğunda benim haritamı ona göre güncelle dedik
    }

    @IBAction func kaydetTiklandi(_ sender: Any) {
        //core dataya kaydetme işlevi bu butonda olacak. Öncelikle contexe ulaşmaya çalışacağız zaten modelimiz belli. Ulaştıktan sonra içerisine NSEntitiy Description ile birlikte insert into yapıcaz yani yeni bir şeyler yazacağız. Daha sonrada tüm işlemlerimizi save edeceğiz -> contexti kullanarak.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext //bu iki işlemi yaptıktan sonra aslında contex' de işlem yapmaya hazırız. Yani context.save() demeye hazırız. Ama demeden önce ayarları yapmamız gerekiyor
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)//entity name -> coredata da oluşturduğum tablo ismi
        yeniYer.setValue(isimTextField.text, forKey: "isim")//verileri core dataya kaydermek için setlemek gerek
        yeniYer.setValue(notTextField.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        do{
            try
            print("kayıt edildi")
        }catch{
            print("hata")
        }
    }
}

