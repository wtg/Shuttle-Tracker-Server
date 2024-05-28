//
//  RunPythonScript.swift
//  Shuttle Tracker Server
//
//  Created by Dylan Zhou on 02/16/24
//

import Foundation
import PythonKit

func RunPythonScript() {
    let sys = Python.import("sys")
    // let file = Python.import("PythonETA")
    print(Python.version)
}