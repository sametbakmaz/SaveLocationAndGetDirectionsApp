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
    
    var secilenIsim = ""//diğer taraftan prepare for sehue ile bunlara ulaşabilmek için 2 adet değişken oluşturduk
    var secilenId : UUID?

    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitue = Double()
    var annotationLongitude = Double()
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
        if secilenIsim != ""{
            //core data dan verileri çek
            if let uuidString = secilenId?.uuidString{//eğer bunu alabiliyorsam uuid yi consola bastım - secilenId? diyerek gelen değeri optional olmaktan çıkartıyor
                print(uuidString)
                //bu uuid ye göre bir filtreleme yaparak veri çekeceğiz. Yine fetchRequest oluşturacağız sadece bir NSPredicate oluşturarak veri çekeceğiz
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")//çekeceğimiz tablo
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)//hangi kolonu neyle filtreleyeceğimizi yazıyoruz. formata yazdığımız "id = %@" -> id si birazdan yazacağım argümanlara eşit olanı getir anlamında kullanılıyor
                fetchRequest.returnsObjectsAsFaults = false
                do{
                    let sonuclar = try context.fetch(fetchRequest)
                        if sonuclar.count > 0 {
                            for sonuc in sonuclar as! [NSManagedObject] {
                                if let isim = sonuc.value(forKey: "isim") as? String{
                                    annotationTitle = isim //yukarıda hepsinin değişkenini tanımladım istediğim yerden erişebilmek için
                                    if let not = sonuc.value(forKey: "not") as? String{
                                        annotationSubtitle = not
                                        if let latitude = sonuc.value(forKey: "latitude") as? Double{
                                            annotationLatitue = latitude
                                            if let longitude = sonuc.value(forKey: "longitude") as? Double{
                                                annotationLongitude = longitude
                                                
                                                //anotasyon koyma, gösterme
                                                let annotation = MKPointAnnotation()
                                                annotation.title = annotationTitle
                                                annotation.subtitle = annotationSubtitle
                                                let coordinate = CLLocationCoordinate2D(latitude: annotationLatitue, longitude: annotationLongitude)
                                                annotation.coordinate = coordinate
                                                
                                                mapView.addAnnotation(annotation)
                                                isimTextField.text = annotationTitle
                                                notTextField.text = annotationSubtitle
                                                
                                                locationManager.stopUpdatingLocation()//güncellemeyi bırak
                                                
                                                //seçtiğimiz konuma gitmesi için kod bloğu altta
                                                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                                let region = MKCoordinateRegion(center: coordinate, span: span)//coordinatımız zaten var ama span imiz yok onuda hemen üstünde oluşturduk
                                                mapView.setRegion(region, animated: true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    
                }catch{
                    print("hata")
                }
                
            }
        }else{
            //yeni veri eklemeye gelmiştir
        }
        
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
    //anotasyon koyduğumuz yerde bilgi kutucuğu oluşturup sağ kısımda işaret çıkarmak için gereken kod
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {//araştır örneklerine bak
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {//gösterdiğimiz butonun üstüne tıklanınca ne olacak
        if secilenIsim != ""{ // daha önce kaydettiğimiz bir yere baktığımıza emin olduk
            let requestLocation = CLLocation(latitude: annotationLatitue, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi, hata) in
            //CLGeocoder bir arayüz kordinatlarla arayüzler arasında bağlantılar yapmaya çalışır.reverseGeocoderLocation ise geocoding işlemini tersten yapmayı sağlar navigasyonu başlatmak için gereken işlemi verecek. Completition Handler'a Entera Basarsak benden placeMark dizisi isteyecek.
            if let placemarks = placemarkDizisi {
                if placemarks.count > 0{
                    let yeniPlacemark = MKPlacemark(placemark: placemarks[0])//navigasyonu açmak içinde harita öğesi oluşturmamız gerekiyordu ve nerde oluşturulacağı ile alakalı placemark istiyor bizden. Bunu bile bilmek içinde güncel konumumuz gösteren Geocoder oluşturduk
                    let item = MKMapItem(placemark: yeniPlacemark)
                    item.name = self.annotationTitle
                    
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]//navigasyonu açmak
                    item.openInMaps(launchOptions: launchOptions)
                }
            }
            //CLPlacemark kullanıcının anlayabileceği bir şekilde oluşturulmuş bir tanımmış ve bir coğrafi konumun oluşturulabileceği anlayabileceği bir tanım
        }
    }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //konumlar güncellendi fonksiyonu ve [CLLocation] bana tek tek güncellenen konumları veriyor yani bu dönen konumu benim alıp işlemem gerek yani locations[0]' ı çağırdığımda kullanabilirim
        //print(locations[0].coordinate.latitude) //enlem
        //print(locations[0].coordinate.longitude) //boylam
        
        if secilenIsim == " "{  //eğer kullanıcı yeni bir yer ekliyorsa bunu yap belirlediğimiz konumu lokasyonu al. Bu yüzden bir yer seçilip gösterilmeyeceğine emin olmak istedik

            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)//bizden delta bekliyor ilk 0.1 0.1 vererek denedik 0.9-0.9 verseydik zoom out açılacaktı konum yani uzaktan yaklaştırılmamış hali
            let location = CLLocationCoordinate2DMake(locations[0].coordinate.latitude,  locations[0].coordinate.longitude)//enlemi ve boylamı alıp location değişkenimde tutuyoruz. Haritada konumumuza gitmemiz için gerekli
            let region = MKCoordinateRegion(center: location, span: span)//Center nereye merkez alıp konumlanacağı yani yukarda oluşturduğumuz location.
            mapView.setRegion(region, animated: true) //bulunduğun bölge öncesinde regionu oluşturmam gerek
            
            //locationManager() fonksiyonunda kısaca her güncelleme olduğunda benim haritamı ona göre güncelle dedik
        }//değilse boş bırakacağım else i yazmama gerek yok
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
            try context.save() //kayıt edildi
            print("kayıt edildi")
        } catch {
            print("hata")
        }
    }
}

