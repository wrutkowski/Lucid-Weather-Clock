//
//  ViewController.swift
//  Lucid Weather Clock
//
//  Created by Wojciech Rutkowski on 07/12/2015.
//  Copyright © 2015 Wojciech Rutkowski. All rights reserved.
//

import UIKit
import CoreLocation
import ForecastIO
import BEMAnalogClock
import INTULocationManager
import Charts

class ViewController: UIViewController, BEMAnalogClockDelegate {

    @IBOutlet weak var clock: BEMAnalogClockView!
    @IBOutlet weak var chart: RadiusPieChartView!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var labelTemperature: UILabel!
    @IBOutlet weak var buttonRefresh: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    fileprivate var clockStartDate = Date()
    fileprivate var clockLoadingAnimationActive = true
    fileprivate var clockDisplayedToken = false
    fileprivate var timerLongPress: Timer?
    fileprivate var forceTouchActionActive = false
    
    fileprivate var location: CLLocation!
    fileprivate var forecast: Forecast?
    fileprivate var placemark: CLPlacemark?
    
    // DEBUG vars
    fileprivate var maxPrecipIntensity: Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.lightGray

        clock.delegate = self
        clock.isUserInteractionEnabled = false
        labelInfo.text = ""
        labelTemperature.text = ""
        chart.alpha = 0.0
        buttonRefresh.isHidden = true
        self.activityIndicator.startAnimating()
        
        refreshForecast()
        
        chart.isUserInteractionEnabled = false
        chart.descriptionText = ""
        chart.noDataText = ""
        chart.noDataTextDescription = ""
        chart.backgroundColor = UIColor.clear
        chart.drawHoleEnabled = false
        chart.drawCenterTextEnabled = false
        chart.drawSliceTextEnabled = false
        chart.usePercentValuesEnabled = false
        chart.legend.enabled = false
        chart.rotationEnabled = false
        chart.rotationAngle = 270.0
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.debugInfo))
        tapGesture.numberOfTapsRequired = 3
        view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.viewDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        clock.alpha = 0.0
        
        configureWatchface()
        
        UIView.animate(withDuration: clockDisplayedToken ? 0.5 : 2.5, animations: { () -> Void in
            self.clock.alpha = 1.0
        }) 
        clockDisplayedToken = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        clock.reloadClock()
    }
    
    func viewDidBecomeActive() {
        clock.alpha = 0.0
        clock.reloadClock()
        
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.clock.alpha = 1.0
        }) 
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        guard let event = event , event.subtype == .motionShake else { return }
        sharePrecipation()
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    //MARK - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if traitCollection.forceTouchCapability == UIForceTouchCapability.unavailable {
            removeTimer()
            timerLongPress = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.showForecastHourly), userInfo: nil, repeats: false)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first , traitCollection.forceTouchCapability == .available else { return }
        
        forceTouchActionActive && touch.maximumPossibleForce / touch.force > 0.5 ? showForecastHourly() : showForecastBest()
        forceTouchActionActive = !forceTouchActionActive
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeTimer()
        showForecastBest()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeTimer()
        showForecastBest()
    }
    
    fileprivate func removeTimer() {
        guard let timerLongPress = timerLongPress else { return }
        timerLongPress.invalidate()
    }
    
    //MARK - Debug
    
    func debugInfo() {
        let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
        let alert = UIAlertController(title: "DEBUG", message: "Max precip intensity: \(maxPrecipIntensity)", preferredStyle: .alert)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }

    //MARK - Clock configuration

    func configureWatchface() {
        // TODO abstract this into a separate file for styling the clock
        clock.enableShadows = true
        clock.faceBackgroundColor = UIColor.clear
        clock.secondHandLength = 0.38 * clock.frame.width
        clock.minuteHandLength = 0.32 * clock.frame.width
        clock.hourHandLength = 0.175 * clock.frame.width
        clock.reloadClock()
    }

    func analogClock(_ clock: BEMAnalogClockView!, graduationLengthFor index: Int) -> CGFloat {
        if index % 15 == 0 {
            return 30
        } else if index % 5 == 0 {
            return 15
        } else {
            return 5
        }
    }

    //MARK: Clock Animations

    func clockLoadingTick() {
        if clockLoadingAnimationActive {
            clockStartDate = clockStartDate.addingTimeInterval(-30)

            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            let components = (calendar as NSCalendar).components([.hour, .minute, .second], from: clockStartDate)

            clock.hours = components.hour!
            clock.minutes = components.minute!
            clock.seconds = components.second!
            clock.updateTime(animated: false)

            self.perform(#selector(ViewController.clockLoadingTick), with: nil, afterDelay: 0.01)
        } else {
            clock.hours = 12
            clock.minutes = 0
            clock.seconds = 0
            clock.updateTime(animated: true)

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.7 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.clock.secondHandAlpha = 1.0
                self.clock.currentTime = true
                self.clock.realTime = true
                self.clock.reloadClock()
                
                UIView.animate(withDuration: 1.5, animations: { () -> Void in
                    self.chart.alpha = 1.0
                })
            }
            
        }
    }

    //MARK: - Actions

    @IBAction func buttonRefreshTapped(_ sender: AnyObject) {
        buttonRefresh.isHidden = true
        self.activityIndicator.startAnimating()
        
        UIView.animate(withDuration: 1.0, animations: { () -> Void in
            self.clock.alpha = 0.0
            self.chart.alpha = 0.0
            }, completion: { (done) -> Void in
                self.refreshForecast()
        }) 
    }

    // MARK: - Forecast

    func refreshForecast() {
        chart.alpha = 0.0
        clock.alpha = 0.0
        clock.secondHandAlpha = 0.0
        clockLoadingAnimationActive = true
        clock.realTime = false
        clock.reloadClock()

        if clockDisplayedToken {
            UIView.animate(withDuration: 2.5, animations: { () -> Void in
                self.clock.alpha = 1.0
            }) 
        }

        clockLoadingTick()

        locateUser()
    }

    func fetchForecast() {
        let forecastClient = APIClient(apiKey: "FORECAST_API_KEY")
        forecastClient.units = .SI
        forecastClient.getForecast(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { (currentForecast, error) -> Void in
            if error != nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
                    let alert = UIAlertController(title: "Weather data error", message: "An error has occured while trying fetch weather data. Please try again later.", preferredStyle: .alert)
                    alert.addAction(okButton)
                    self.present(alert, animated: true, completion: nil)

                    self.buttonRefresh.isHidden = false
                    self.activityIndicator.stopAnimating()
                })
            } else {
//                print(currentForecast)

                self.forecast = currentForecast
                DispatchQueue.main.async(execute: { () -> Void in
                    self.updateInfo()
                    self.clockLoadingAnimationActive = false
                    if let currentForecast = currentForecast {
                        self.adjustDesignToWeather(currentForecast)
                    }
                    
                    self.buttonRefresh.isHidden = false
                    self.activityIndicator.stopAnimating()
                })
            }
        }
    }
    
    func showForecastHourly() {
        if let hourlyData = forecast?.hourly?.data {
            showPieData(hourlyData, minutely: false)
        }
    }
    
    func showForecastMinutely() {
        if let minutelyData = forecast?.minutely?.data {
            showPieData(minutelyData, minutely: true)
        }
    }
    
    func showForecastBest() {
        if let minutelyData = forecast?.minutely?.data {
            showPieData(minutelyData, minutely: true)
        } else if let hourlyData = forecast?.hourly?.data {
            showPieData(hourlyData, minutely: false)
        }
    }

    //MARK: - Location

    func locateUser() {
        INTULocationManager.sharedInstance().requestLocation(withDesiredAccuracy: .neighborhood, timeout: 5, delayUntilAuthorized: true) { (location, accuracy, status) -> Void in
            switch status {
            case .success:
                self.location = location
                self.fetchForecast()
                self.fetchGeoData()
            case .servicesDenied, .servicesDisabled, .servicesNotDetermined, .servicesRestricted:
                let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
                let alert = UIAlertController(title: "Location unavailable", message: "Please ensure that location service is available for Lucid Weather Clock in Settings. We are unable to show you the weather for now.", preferredStyle: .alert)
                alert.addAction(okButton)
                self.present(alert, animated: true, completion: nil)

                self.buttonRefresh.isHidden = false
                self.activityIndicator.stopAnimating()
            case .error:
                let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
                let alert = UIAlertController(title: "Location error", message: "An error has occured while trying to determine your location. Please try again later.", preferredStyle: .alert)
                alert.addAction(okButton)
                self.present(alert, animated: true, completion: nil)

                self.buttonRefresh.isHidden = false
                self.activityIndicator.stopAnimating()
            default:
                break
            }
        }
    }

    func fetchGeoData() {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if let e = error {
                print("Reverse geocoder failed with error" + e.localizedDescription)
                return
            }

            if let placemarks = placemarks {
                if placemarks.count > 0 {
                    self.placemark = placemarks[0]
                    self.updateInfo()
                }
            }
        })
    }

    //MARK: - Design

    func adjustDesignToWeather(_ forecast: Forecast) {
        if let temp = forecast.currently?.apparentTemperature {
            print(temp)

            labelTemperature.text = "\(Int(round(temp)))°C"

            // color
            let color = ColorManager.convertTemperatureToColor(temp)
            UIView.animate(withDuration: 1.0, animations: { () -> Void in
                self.view.backgroundColor = color.toUIColor
            })
        }

        showForecastBest()
    }
    
    func showPieData(_ data: [DataPoint], minutely: Bool = true) {
        var forecastData = [ForecastDataEntry]()
        
        for unitData in data {
            if forecastData.count >= (minutely ? 60 : 12) {
                break
            }
            
            var timeUnit: Int = 0
            var precipIntensity: Float = 0
            var precipProbability: Float = 0
            let components = NSCalendar.current.dateComponents([.hour, .minute], from: unitData.time)
            if minutely {
                timeUnit = components.minute!
            } else {
                timeUnit = components.hour!
                if timeUnit > 12 {
                    timeUnit -= 12
                }
            }
            
            if let precipIntensityUnwrap = unitData.precipIntensity {
                precipIntensity = precipIntensityUnwrap
            }
            if let precipProbabilityUnwrap = unitData.precipProbability {
                precipProbability = precipProbabilityUnwrap
            }
            
            if precipIntensity > maxPrecipIntensity {
                maxPrecipIntensity = precipIntensity
            }
            
            //print("time: \(timeUnit), precipProbability: \(precipProbability), precipIntensity: \(precipIntensity) -> \(min(precipIntensity, 0.9))")
            
            precipIntensity = min(precipIntensity, 0.9)
            
            forecastData.append(ForecastDataEntry(timeUnit: timeUnit, precipIntensity: precipIntensity, precipProbability: precipProbability))
        }
        
        forecastData.sort { $0.timeUnit < $1.timeUnit }
        
        var yVals = [ChartDataEntry]()
        var colors = [UIColor]()
        
        let sliceSize: Double = minutely ? 6/360 : 30/360
        for forecastEntry in forecastData {
            yVals.append(ChartDataEntry(value: sliceSize, xIndex: forecastEntry.timeUnit, data: Double(forecastEntry.precipIntensity)))
            colors.append(UIColor.white.withAlphaComponent(CGFloat(forecastEntry.precipProbability)))
        }
        
        let set = PieChartDataSet(yVals: yVals, label: "")
        set.colors = colors
        set.drawValuesEnabled = false
        
        var xVals = [String]()
        xVals.append(minutely ? "60" : "12")
        for i in 1..<(minutely ? 60 : 12) {
            xVals.append("\(i)")
        }
        let data = PieChartData(xVals: xVals, dataSet: set)
        
        chart.data = data
    }

    func updateInfo() {
        if let time = forecast?.currently?.time {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "H:mm"

            labelInfo.text = "Last updated: \(dateFormatter.string(from: time))"

            if let place = placemark {
                if let locality = place.locality, let thoroughfare = place.thoroughfare {
                    labelInfo.text = "\(labelInfo.text!) @ \(thoroughfare), \(locality)"
                } else if let locality = place.locality {
                    labelInfo.text = "\(labelInfo.text!) @ \(locality)"
                }
            }
        } else {
            labelInfo.text = ""
        }
    }
    
    //MARK - Share

    func captureClockChart() -> UIImage? {
        var image: UIImage?
        
        let imageSize = CGSize(width: clock.bounds.size.width * 1.2, height: clock.bounds.size.height * 1.4)
        UIGraphicsBeginImageContextWithOptions(imageSize, true, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            // background color
            view.backgroundColor?.set()
            UIGraphicsGetCurrentContext()?.fill(CGRect(origin: CGPoint.zero, size: imageSize))
            
            // temperature label
            var offsetX = (imageSize.width - labelTemperature.bounds.size.width)/2
            var offsetY = imageSize.height * 0.13 - labelTemperature.bounds.size.height/2
            context.translateBy(x: offsetX, y: offsetY)
            labelTemperature.layer.render(in: context)
            context.translateBy(x: -offsetX, y: -offsetY)
            
            // chart and clock
            offsetX = imageSize.width * 0.08
            offsetY = imageSize.height * 0.2
            context.translateBy(x: offsetX, y: offsetY)
            chart.layer.render(in: context)
            clock.layer.render(in: context)
            context.translateBy(x: -offsetX, y: -offsetY)
            
            // copyright label
            let copyrightLabel = UILabel(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: 10))
            copyrightLabel.font = UIFont(name: labelTemperature.font.familyName, size: 8.0)
            copyrightLabel.textColor = UIColor.white
            copyrightLabel.textAlignment = .center
            copyrightLabel.text = "brought by Lucid Weather Clock, data by Forecast.io"
            offsetX = 0.0
            offsetY = imageSize.height * 0.98 - copyrightLabel.bounds.size.height/2
            context.translateBy(x: offsetX, y: offsetY)
            copyrightLabel.layer.render(in: context)
            context.translateBy(x: -offsetX, y: -offsetY)
            
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func sharePrecipation() {
        if let image = captureClockChart() {
            var location = ""
            if let locality = placemark?.locality {
                location = " @ \(locality)"
            }
            let activityVC = UIActivityViewController(activityItems: ["Current precipation\(location) brought by @LucidWeatherClock", image], applicationActivities: nil)
            present(activityVC, animated: true, completion: nil)
        }
    }
}
