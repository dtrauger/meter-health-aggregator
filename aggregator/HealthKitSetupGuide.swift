//
//  HealthKitSetupGuide.swift
//  aggregator
//
//  Created by Derek Trauger on 11/5/25.
//

/*
 IMPORTANT: HealthKit Setup Required
 
 To use HealthKit in your app, you need to:
 
 1. Add HealthKit capability to your app:
    - In Xcode, go to your app target
    - Select "Signing & Capabilities"
    - Click "+ Capability"
    - Add "HealthKit"
 
 2. Add privacy usage descriptions to Info.plist:
    Add these keys to your Info.plist file:
 
    <key>NSHealthShareUsageDescription</key>
    <string>This app needs access to your health data to display personalized health metrics and trends.</string>
    
    <key>NSHealthUpdateUsageDescription</key>
    <string>This app may update your health data when syncing with other health apps.</string>
 
 3. The following health data types are requested:
    - Heart Rate
    - Body Mass (Weight)
    - Oxygen Saturation
    - Blood Glucose
    - Blood Pressure (Systolic & Diastolic)  
    - Respiratory Rate
 
 After completing these steps, the HealthDataView will be able to:
 - Request HealthKit authorization
 - Fetch health data from the last 30 days
 - Display interactive charts using Swift Charts
 - Show a data table with recent values
 - Persist health data using SwiftData
 
 Usage:
 The app now has two tabs:
 1. Items - Your original functionality
 2. Health - New HealthKit integration with charts and data tables
*/

import SwiftUI

// This is just a documentation file - no actual code needed