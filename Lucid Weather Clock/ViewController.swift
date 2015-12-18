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
    @IBOutlet weak var chart: PieChartView!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var labelTemperature: UILabel!
    @IBOutlet weak var buttonRefresh: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    private var clockStartDate = NSDate()
    private var clockLoadingAnimationActive = true
    private var clockDisplayedToken = false

    private var location: CLLocation!
    private var forecast: Forecast?
    private var placemark: CLPlacemark?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.lightGrayColor()

        clock.delegate = self
        labelInfo.text = ""
        labelTemperature.text = ""
        chart.alpha = 0.0
        buttonRefresh.hidden = true
        self.activityIndicator.startAnimating()
        
        refreshForecast()
        
        chart.descriptionText = ""
        chart.noDataText = ""
        chart.noDataTextDescription = ""
        chart.backgroundColor = UIColor.clearColor()
        chart.drawHoleEnabled = false
        chart.drawCenterTextEnabled = false
        chart.drawSliceTextEnabled = false
        chart.usePercentValuesEnabled = false
        chart.legend.enabled = false
        chart.rotationEnabled = false
        chart.rotationAngle = 270.0
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        clock.alpha = 0.0
        
        configureWatchface()
        
        UIView.animateWithDuration(clockDisplayedToken ? 0.5 : 2.5) { () -> Void in
            self.clock.alpha = 1.0
        }
        clockDisplayedToken = true
        
        NSNotificationCenter.defaultCenter().addObserver(clock, selector: Selector("reloadClock"), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(clock, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        clock.reloadClock()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK - Clock configuration

    func configureWatchface() {
        clock.enableShadows = true
        clock.faceBackgroundColor = UIColor.clearColor()
        clock.secondHandLength = 0.38 * clock.frame.width
        clock.minuteHandLength = 0.32 * clock.frame.width
        clock.hourHandLength = 0.175 * clock.frame.width
        clock.reloadClock()
    }

    func analogClock(clock: BEMAnalogClockView!, graduationLengthForIndex index: Int) -> CGFloat {
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
            clockStartDate = clockStartDate.dateByAddingTimeInterval(-30)

            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
            let components = calendar.components([.Hour, .Minute, .Second], fromDate: clockStartDate)

            clock.hours = components.hour
            clock.minutes = components.minute
            clock.seconds = components.second
            clock.updateTimeAnimated(false)

            self.performSelector(Selector("clockLoadingTick"), withObject: nil, afterDelay: 0.01)
        } else {
            clock.hours = 12
            clock.minutes = 0
            clock.seconds = 0
            clock.updateTimeAnimated(true)

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.7 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.clock.secondHandAlpha = 1.0
                self.clock.currentTime = true
                self.clock.realTime = true
                self.clock.reloadClock()
                
                UIView.animateWithDuration(1.5, animations: { () -> Void in
                    self.chart.alpha = 1.0
                })
            }
            
        }
    }

    //MARK: - Actions

    @IBAction func buttonRefreshTapped(sender: AnyObject) {
        buttonRefresh.hidden = true
        self.activityIndicator.startAnimating()
        
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.clock.alpha = 0.0
            self.chart.alpha = 0.0
            }) { (done) -> Void in
                self.refreshForecast()
        }
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
            UIView.animateWithDuration(2.5) { () -> Void in
                self.clock.alpha = 1.0
            }
        }

        clockLoadingTick()

        locateUser()
    }

    func fetchForecast() {
        let forecastClient = APIClient(apiKey: "FORECAST_API_KEY")
        forecastClient.getForecast(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { (currentForecast, error) -> Void in
            if error != nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    let alert = UIAlertController(title: "Weather data error", message: "An error has occured while trying fetch weather data. Please try again later.", preferredStyle: .Alert)
                    alert.addAction(okButton)
                    self.presentViewController(alert, animated: true, completion: nil)

                    self.buttonRefresh.hidden = false
                    self.activityIndicator.stopAnimating()
                })
            } else {
                print(currentForecast)

                self.forecast = currentForecast
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.updateInfo()
                    self.clockLoadingAnimationActive = false
                    if let currentForecast = currentForecast {
                        self.adjustDesignToWeather(currentForecast)
                    }
                    
                    self.buttonRefresh.hidden = false
                    self.activityIndicator.stopAnimating()
                })
            }
        }
    }

    //MARK: - Location

    func locateUser() {
        INTULocationManager.sharedInstance().requestLocationWithDesiredAccuracy(.Neighborhood, timeout: 5, delayUntilAuthorized: true) { (location, accuracy, status) -> Void in
            switch status {
            case .Success:
                self.location = location
                self.fetchForecast()
                self.fetchGeoData()
            case .ServicesDenied, .ServicesDisabled, .ServicesNotDetermined, .ServicesRestricted:
                let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
                let alert = UIAlertController(title: "Location unavailable", message: "Please ensure that location service is available for Lucid Weather Clock in Settings. We are unable to show you the weather for now.", preferredStyle: .Alert)
                alert.addAction(okButton)
                self.presentViewController(alert, animated: true, completion: nil)

                self.buttonRefresh.hidden = false
                self.activityIndicator.stopAnimating()
            case .Error:
                let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
                let alert = UIAlertController(title: "Location error", message: "An error has occured while trying to determine your location. Please try again later.", preferredStyle: .Alert)
                alert.addAction(okButton)
                self.presentViewController(alert, animated: true, completion: nil)

                self.buttonRefresh.hidden = false
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

    func adjustDesignToWeather(forecast: Forecast) {
        if let temp = forecast.currently?.apparentTemperature {
            print(temp)

            labelTemperature.text = "\(Int(round(temp)))°C"

            // color
            let color = ColorManager.convertTemperatureToColor(temp)
            UIView.animateWithDuration(1.0, animations: { () -> Void in
                self.view.backgroundColor = color.toUIColor
            })
        }

        if let minutelyData = forecast.minutely?.data {
            showPieData(minutelyData, minutely: true)
        } else if let hourlyData = forecast.hourly?.data {
            showPieData(hourlyData, minutely: false)
        }

    }
    
    func showPieData(data: [DataPoint], minutely: Bool = true) {
        var forecastData = [ForecastDataEntry]()
        var maxPrecipIntensity: Float = 0
        
        for unitData in data {
            if forecastData.count >= (minutely ? 60 : 12) {
                break
            }
            
            var timeUnit: Int = 0
            var precipIntensity: Float = 0
            var precipProbability: Float = 0
            
            let components = NSCalendar.currentCalendar().components([.Hour, .Minute], fromDate: unitData.time)
            if minutely {
                timeUnit = components.minute
            } else {
                timeUnit = components.hour
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
            // testing chart rotation
            //                if timeMin == 0 {
            //                    precipIntensity = 100
            //                    precipProbability = 1.0
            //                }
            
            print("time: \(timeUnit), precipProbability: \(precipProbability), precipIntensity: \(precipIntensity) -> \(min(precipIntensity, 0.9))")
            
            precipIntensity = min(precipIntensity, 0.9)
            
            forecastData.append(ForecastDataEntry(timeUnit: timeUnit, precipIntensity: precipIntensity, precipProbability: precipProbability))
        }
        
//        labelTemperature.text = labelTemperature.text! + " - \(maxPrecipIntensity)"
        forecastData.sortInPlace { $0.timeUnit < $1.timeUnit }
        
        var yVals = [ChartDataEntry]()
        var colors = [UIColor]()
        
        let sliceSize: Double = minutely ? 6/360 : 30/360
        for forecastEntry in forecastData {
            yVals.append(ChartDataEntry(value: sliceSize, xIndex: forecastEntry.timeUnit, data: Double(forecastEntry.precipIntensity)))
            colors.append(UIColor.whiteColor().colorWithAlphaComponent(CGFloat(forecastEntry.precipProbability)))
        }
        
        let set = PieChartDataSet(yVals: yVals)
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
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "H:mm"

            labelInfo.text = "Last updated: \(dateFormatter.stringFromDate(time))"

            if let place = placemark {
                if let locality = place.locality, thoroughfare = place.thoroughfare {
                    labelInfo.text = "\(labelInfo.text!) @ \(thoroughfare), \(locality)"
                } else if let locality = place.locality {
                    labelInfo.text = "\(labelInfo.text!) @ \(locality)"
                }
            }
        } else {
            labelInfo.text = ""
        }
    }
}
