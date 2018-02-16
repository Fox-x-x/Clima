

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON


class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "e72ca729af228beabd5d20e3b7749713"
    
    enum TemperatureType {
        case Fahrenheit
        case Celsius
    }

    //TODO: Declare instance variables here
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    
    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var tLabel: UILabel!
    @IBOutlet weak var tSwitchOnOff: UISwitch!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //TODO:Set up the location manager here.
        self.temperatureLabel.text = ""
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
    }
    
    
    //Switch (From C to F), converts the t from C to F and vise versa
    func convertTemperature(fromLabel: UILabel, into: TemperatureType) -> String {
        var tmp: String = ""
        
        if fromLabel.text != "" {
            let noDeg = fromLabel.text!.split(separator: "°")
            if var tmpTemperature = Double(noDeg[0]) {
                if into == .Fahrenheit {
                    tmpTemperature = (tmpTemperature * 1.8) + 32
                    tmp = String(NSString(format:"%.1f", tmpTemperature))
                }
                else if into == .Celsius {
                    tmpTemperature = (tmpTemperature - 32) / 1.8
                    tmp = String(NSString(format:"%.1f", tmpTemperature))
                }
            }
        }
        return tmp + "°"
    }
    
    
    
    @IBAction func tSwitch(_ sender: UISwitch) {
        if sender.isOn {
            temperatureLabel.text = convertTemperature(fromLabel: temperatureLabel, into: .Fahrenheit)
        }
        else {
            temperatureLabel.text = convertTemperature(fromLabel: temperatureLabel, into: .Celsius)
        }
    }
    
    
    
    
    //MARK: - Networking
    /***************************************************************/
    
    //Write the getWeatherData method here:
    func getWeatherData(url: String, parameters: [String: String]) {
        
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                
                print("Success! Got the weather data")
                let weatherJSON : JSON = JSON(response.result.value!)
                self.updateWeatherData(json: weatherJSON)
                
//                print(weatherJSON)
//                self.updateWeatherData(json: weatherJSON)
                
            }
            else {
                print("Error \(response.result.error!)")
                self.cityLabel.text = "Connection issues"
                self.temperatureLabel.text = ""
            }
        }
        
    }
    
    
    
    
    //MARK: - JSON Parsing
    /***************************************************************/
   
    
    //Write the updateWeatherData method here:
    func updateWeatherData(json: JSON) {
        
        if let tempResult = json["main"]["temp"].double {
            print("origin temperature = \(tempResult)")
            print(NSString(format:"%.1f", tempResult))
            if tSwitchOnOff.isOn {
                weatherDataModel.temperature = ((tempResult - 273.15) * 1.8) + 32
            }
            else {
                weatherDataModel.temperature = tempResult - 273.15
            }
            print("temperature= \(weatherDataModel.temperature)")
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            updateUIWeatherData()
        }
        else {
            cityLabel.text = "Weather unavailable"
            temperatureLabel.text = ""
        }
    }

    
    
    
    //MARK: - UI Updates
    /***************************************************************/
    
    
    //UISwitch method here:

    
    
    //Write the updateUIWithWeatherData method here:
    func updateUIWeatherData() {
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = "\(NSString(format:"%.1f", weatherDataModel.temperature))°"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }
    
    
    
    
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            
            locationManager.stopUpdatingLocation()
            
            print("longitude = \(location.coordinate.longitude), latitude = \(location.coordinate.latitude)")
            
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            
            let params : [String : String] = ["lat" : latitude, "lon" : longitude, "appid" : APP_ID]
            
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location unavailable"
    }
    
    

    
    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    
    //Write the userEnteredANewCityName Delegate method here:
    func userEnteredANewCityName(city: String) {
        let params : [String : String] = ["q" : city, "appid" : APP_ID]
        getWeatherData(url: WEATHER_URL, parameters: params)
    }
    

    
    //Write the PrepareForSegue Method here
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            let destinationVC = segue.destination as! ChangeCityViewController
            destinationVC.delegate = self
        }
    }
    
    
    
    
}


