#!/usr/bin/env swift

// Read the code coverage of code changes and fail if it is lower than the quality gate threshold
//
import Foundation

let coverageThreshold = 80.0

// The data models waere generated from JSON Schema using quicktype,

// MARK: - XCResult
struct XCResult: Codable {
    let coveredLines, executableLines: Int
    let lineCoverage: Double
    let targets: [Target]
}

// MARK: - Target
struct Target: Codable {
    let buildProductPath: String
    let coveredLines, executableLines: Int
    let files: [File]
    let lineCoverage: Double
    let name: String
}

// MARK: - File
struct File: Codable {
    let coveredLines, executableLines: Int
    let functions: [Function]
    let lineCoverage: Double
    let name, path: String
}

// MARK: - Function
struct Function: Codable {
    let coveredLines, executableLines, executionCount: Int
    let lineCoverage: Double
    let lineNumber: Int
    let name: String
}

// MARK: - ChangedFile
struct ChangedFile {
    let target: String
    let name: String
}

struct ChangedFileCoverage {
    let target: String
    let name: String
    let lineCoverage: Double
    let passing: Bool
}

let changedFilesRaw = shell("bash ./scripts/filterSourceChanges.sh")
let changedFiles = parseRawChangedFiles(rawData: changedFilesRaw)

if changedFiles.count == 0 {
    print("Success. ".colored(.green) + "No changes found. Check that new sources have been added to Git.")
    exit(0)
}

let decimalFormatter = NumberFormatter()
decimalFormatter.numberStyle = .decimal
decimalFormatter.minimumFractionDigits = 2
decimalFormatter.maximumFractionDigits = 2

let arguments = CommandLine.arguments

guard arguments.count == 2 else {
    print("Incorrect parameters. Include JSON file generated by \"xcrun xccov view --report --json <tests.xcresult> \"")
    print("Usage: <script> file.JSON")
    exit(1)
}

let file = CommandLine.arguments[1]
let currentDirectoryPath = FileManager.default.currentDirectoryPath
let filePath = currentDirectoryPath + "/" + file

guard let json = try? String(contentsOfFile: filePath, encoding: .utf8), let data = json.data(using: .utf8) else {
    print("Error: Invalid JSON at path: \(filePath)")
    exit(1)
}
guard let report = try? JSONDecoder().decode(XCResult.self, from: data) else {
    print("Error: Could not decode the report.")
    exit(1)
}

let changedFilesWithCoverage = extractCoverageForCodeChanges(report: report, changedFiles: changedFiles)

print("")
print("Code Coverage Report".colored(.cyan))
print("--------------------")
var result = true

for file in changedFilesWithCoverage {
    if !file.passing {
        result = false
    }
    
    let icon = file.passing ? "✓".colored(.green) : "⨯".colored(.red)
    let target = "\(file.target)".colored(.cyan)
    
    print("    \(icon) [\(target)] \(file.name) (\(String(describing: file.lineCoverage))%)")
}

if result {
    print("Success".colored(.green))
    exit(0)
} else {
    print("Fail, please add code coverage in the files indicated above.".colored(.red))
    exit(1)
}

// MARK: Convert the normalised coverage to a percentage
func roundDouble(input: Double) -> Double {
    let printableCoverage = decimalFormatter.string(from: NSNumber(value: input)) ?? "0.0"
    return Double(printableCoverage) ?? 0.0
}

// MARK: Iterate over the changes and extract out the coverage
func extractCoverageForCodeChanges(report: XCResult, changedFiles: [ChangedFile]) -> [ChangedFileCoverage] {
    var changedFilesWithCoverage = [ChangedFileCoverage]()
    
    for target in report.targets {
        for changedFile in changedFiles {
            if target.name == changedFile.target {
                for file in target.files {
                    if file.name == changedFile.name {
                        let coveragePercent = roundDouble(input: file.lineCoverage * 100.0)
                        let passing = coveragePercent > coverageThreshold
                        let changedFileCoverage = ChangedFileCoverage(target: changedFile.target,
                                                                      name: file.name,
                                                                      lineCoverage: coveragePercent,
                                                                      passing: passing)
                        changedFilesWithCoverage.append(changedFileCoverage)
                    }
                }
            }
        }
    }
    
    return changedFilesWithCoverage
}

// MARK: - shell wrapper function
func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

// MARK: - parseRawChangedFiles
func parseRawChangedFiles(rawData: String) -> [ChangedFile] {
    let trimmedFeatures = rawData.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    let arrayOfChanges = Array(Set(trimmedFeatures.components(separatedBy: " ")))
    
    var changedFiles = [ChangedFile]()
    
    // for these components we need the first and the last
    for file in arrayOfChanges {
        let pathComponents = file.components(separatedBy: "/")
        if pathComponents.count < 4 { // simple check for the path structue
            break
        }
        
        guard let target = pathComponents.first else {
            print("Changed file parsing error: \(file) is not a valid file")
            exit(1)
        }
        
        guard let name = pathComponents.last else {
            print("Changed file parsing error: \(file) is not a valid file")
            exit(1)
        }
        
        if !name.contains("swift") {
            print("Changed file parsing error: \(file) is not a valid Swift source file")
            exit(1)
        }
        
        let changedFile = ChangedFile(target: target + ".framework", name: name)
        
        changedFiles.append(changedFile)
    }
    
    return changedFiles
}

enum ANSIColor: String {
    typealias This = ANSIColor
    
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case `default` = "\u{001B}[0;0m"
    
    static var values: [This] {
        return [.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white, .default]
    }

    static func + (lhs: This, rhs: String) -> String {
        return lhs.rawValue + rhs
    }

    static func + (lhs: String, rhs: This) -> String {
        return lhs + rhs.rawValue
    }
}

extension String {

    func colored(_ color: ANSIColor) -> String {
        return color + self + ANSIColor.default
    }

    var black: String {
        return colored(.black)
    }

    var red: String {
        return colored(.red)
    }

    var green: String {
        return colored(.green)
    }

    var yellow: String {
        return colored(.yellow)
    }

    var blue: String {
        return colored(.blue)
    }

    var magenta: String {
        return colored(.magenta)
    }

    var cyan: String {
        return colored(.cyan)
    }

    var white: String {
        return colored(.white)
    }
}
