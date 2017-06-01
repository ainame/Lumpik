import Foundation
import Swiftkiq

var options = LaunchOptions()
options.connectionPool = 25

let router = Router()
CLI.start(router: router, launchOptions: options)
