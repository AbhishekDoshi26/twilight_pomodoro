//
//  extensionBundle.swift
//  extension
//
//  Created by Abhishek Doshi on 18/02/26.
//

import WidgetKit
import SwiftUI

@main
struct PomodoroWidgetBundle: WidgetBundle {
    var body: some Widget {
        PomodoroWidget()
        PomodoroWidgetControl()
    }
}
