import OSLog

enum PekisLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? AppConfiguration.bundleIdentifier

    static let app = Logger(subsystem: subsystem, category: "App")
    static let cloudKit = Logger(subsystem: subsystem, category: "CloudKit")
    static let gameplay = Logger(subsystem: subsystem, category: "Gameplay")
}
