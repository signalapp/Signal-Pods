
import XCTest
import CocoaLumberjack

@objc
public class MobileCoinProtosSwiftTest: XCTestCase {
    
    @objc
    public override func setUp() {
        super.setUp()
        
        DDLog.add(DDTTYLogger.sharedInstance!)
    }
    
    @objc
    public override func tearDown() {
    }
}
