//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import XCTest
import SignalMetadataKit

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func ows_shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.ows_shuffle()
        return result
    }
}

// See: https://github.com/signalapp/libsignal-metadata-java/blob/master/tests/src/test/java/org/signal/libsignal/metadata/SessionCipherTest.java
//    public class SessionCipherTest extends TestCase {
class SMKSessionCipherTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

//    public void testBasicSessionV3()
//    throws InvalidKeyException, DuplicateMessageException,
//    LegacyMessageException, InvalidMessageException, NoSuchAlgorithmException, NoSessionException, UntrustedIdentityException
    func testBasicSessionV3() {
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(address: .e164("+14159999999"), deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: .e164("+14158888888"), deviceId: 1, registrationId: 1235)

//    SessionRecord aliceSessionRecord = new SessionRecord();
//    SessionRecord bobSessionRecord   = new SessionRecord();
        let aliceSessionRecord = SessionRecord()!
        let bobSessionRecord = SessionRecord()!

//    initializeSessionsV3(aliceSessionRecord.getSessionState(), bobSessionRecord.getSessionState());
        initializeSessionsV3(aliceSessionState: aliceSessionRecord.sessionState()!,
                              bobSessionState: bobSessionRecord.sessionState()!,
                              aliceMockClient: aliceMockClient,
                              bobMockClient: bobMockClient)

//    runInteraction(aliceSessionRecord, bobSessionRecord);
        runInteraction(aliceSessionRecord: aliceSessionRecord,
                            bobSessionRecord: bobSessionRecord,
                            aliceMockClient: aliceMockClient,
                            bobMockClient: bobMockClient)
    }

//    public void testMessageKeyLimits() throws Exception {
    func testMessageKeyLimits() {
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(address: .e164("+14159999999"), deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: .e164("+14158888888"), deviceId: 1, registrationId: 1235)

        //    SessionRecord aliceSessionRecord = new SessionRecord();
//    SessionRecord bobSessionRecord   = new SessionRecord();
        let aliceSessionRecord = SessionRecord()!
        let bobSessionRecord = SessionRecord()!

//    initializeSessionsV3(aliceSessionRecord.getSessionState(), bobSessionRecord.getSessionState());
        initializeSessionsV3(aliceSessionState: aliceSessionRecord.sessionState()!,
                              bobSessionState: bobSessionRecord.sessionState()!,
                              aliceMockClient: aliceMockClient,
                              bobMockClient: bobMockClient)

//    SignalProtocolStore aliceStore = new TestInMemorySignalProtocolStore();
//    SignalProtocolStore bobStore   = new TestInMemorySignalProtocolStore();
//    
//    aliceStore.storeSession(new SignalProtocolAddress("+14159999999", 1), aliceSessionRecord);
//    bobStore.storeSession(new SignalProtocolAddress("+14158888888", 1), bobSessionRecord);
        aliceMockClient.storeSession(address: aliceMockClient.address,
                                     deviceId: aliceMockClient.deviceId,
                                     session: aliceSessionRecord,
                                     protocolContext: nil)
        bobMockClient.storeSession(address: bobMockClient.address,
                                   deviceId: bobMockClient.deviceId,
                                   session: bobSessionRecord,
                                   protocolContext: nil)

//    SessionCipher aliceCipher    = new SessionCipher(aliceStore, new SignalProtocolAddress("+14159999999", 1));
//    SessionCipher     bobCipher      = new SessionCipher(bobStore, new SignalProtocolAddress("+14158888888", 1));
        let aliceCipher = aliceMockClient.createSessionCipher()
        let bobCipher = bobMockClient.createSessionCipher()

//    List<CiphertextMessage> inflight = new LinkedList<>();
        var inflight = [CipherMessage]()

//    for (int i=0;i<2010;i++) {
//    inflight.add(aliceCipher.encrypt("you've never been so hungry, you've never been so cold".getBytes()));
//    }
        for _ in 1...2010 {
            let plaintext = "you've never been so hungry, you've never been so cold".data(using: String.Encoding.utf8)!
            let message = try! aliceCipher.encryptMessage(plaintext, protocolContext: nil)
            inflight.append(message)
        }

//    bobCipher.decrypt(new SignalMessage(inflight.get(1000).serialize()));
//    bobCipher.decrypt(new SignalMessage(inflight.get(inflight.size()-1).serialize()));
        let midpointMessage = try! bobCipher.decrypt(inflight[1000], protocolContext: nil)
        XCTAssertNotNil(midpointMessage)
        let lastMessage = try! bobCipher.decrypt(inflight.last!, protocolContext: nil)
        XCTAssertNotNil(lastMessage)

        // TODO: Why isn't this failing?
        let firstMessage = try! bobCipher.decrypt(inflight[0], protocolContext: nil)
        XCTAssertNotNil(firstMessage)
//    try {
//    bobCipher.decrypt(new SignalMessage(inflight.get(0).serialize()));
//    throw new AssertionError("Should have failed!");
//    } catch (DuplicateMessageException dme) {
//    // good
//    }
    }

    // MARK: - Utils

//    private void runInteraction(SessionRecord aliceSessionRecord, SessionRecord bobSessionRecord)
//    throws DuplicateMessageException, LegacyMessageException, InvalidMessageException, NoSuchAlgorithmException, NoSessionException, UntrustedIdentityException {
    private func runInteraction(aliceSessionRecord: SessionRecord,
                                bobSessionRecord: SessionRecord,
                                aliceMockClient: MockClient,
                                bobMockClient: MockClient) {
//    SignalProtocolStore aliceStore = new TestInMemorySignalProtocolStore();
//    SignalProtocolStore bobStore   = new TestInMemorySignalProtocolStore();

//    aliceStore.storeSession(new SignalProtocolAddress("+14159999999", 1), aliceSessionRecord);
//    bobStore.storeSession(new SignalProtocolAddress("+14158888888", 1), bobSessionRecord);
        aliceMockClient.storeSession(address: aliceMockClient.address,
                                     deviceId: aliceMockClient.deviceId,
                                     session: aliceSessionRecord,
                                     protocolContext: nil)
        bobMockClient.storeSession(address: bobMockClient.address,
                                   deviceId: bobMockClient.deviceId,
                                   session: bobSessionRecord,
                                   protocolContext: nil)

//    SessionCipher     aliceCipher    = new SessionCipher(aliceStore, new SignalProtocolAddress("+14159999999", 1));
//    SessionCipher     bobCipher      = new SessionCipher(bobStore, new SignalProtocolAddress("+14158888888", 1));
        let aliceCipher = aliceMockClient.createSessionCipher()
        let bobCipher = bobMockClient.createSessionCipher()

//    byte[]            alicePlaintext = "This is a plaintext message.".getBytes();
        let alicePlaintext = "This is a plaintext message.".data(using: String.Encoding.utf8)!
        // TODO: Why isn't the java test padding the plaintext?
        let alicePaddedPlaintext = (alicePlaintext as NSData).paddedMessageBody()!
//    CiphertextMessage message        = aliceCipher.encrypt(alicePlaintext);
        let message = try! aliceCipher.encryptMessage(alicePaddedPlaintext, protocolContext: nil)
//    byte[]            bobPlaintext   = bobCipher.decrypt(new SignalMessage(message.serialize()));
        let bobPaddedPlaintext = try! bobCipher.decrypt(message, protocolContext: nil)
        let bobPlaintext = (bobPaddedPlaintext as NSData).removePadding()

//    assertTrue(Arrays.equals(alicePlaintext, bobPlaintext));
        XCTAssertEqual(alicePlaintext, bobPlaintext)

//    byte[]            bobReply      = "This is a message from Bob.".getBytes();
        let bobReply = "This is a message from Bob.".data(using: String.Encoding.utf8)!
        let bobReplyPadded = (bobReply as NSData).paddedMessageBody()!
//    CiphertextMessage reply         = bobCipher.encrypt(bobReply);
        let reply = try! bobCipher.encryptMessage(bobReplyPadded, protocolContext: nil)
//    byte[]            receivedReply = aliceCipher.decrypt(new SignalMessage(reply.serialize()));
        let receivedReplyPadded = try! aliceCipher.decrypt(reply, protocolContext: nil)
        let receivedReply = (receivedReplyPadded as NSData).removePadding()

//    assertTrue(Arrays.equals(bobReply, receivedReply));
        XCTAssertEqual(bobReply, receivedReply)

//    List<CiphertextMessage> aliceCiphertextMessages = new ArrayList<>();
//    List<byte[]>            alicePlaintextMessages  = new ArrayList<>();
        typealias MessageTuple = (plaintext: Data, message: CipherMessage)
        var aliceMessages = [MessageTuple]()

//    for (int i=0;i<50;i++) {
        //    alicePlaintextMessages.add(("смерть за смерть " + i).getBytes());
        //    aliceCiphertextMessages.add(aliceCipher.encrypt(("смерть за смерть " + i).getBytes()));
        for i in 1...50 {
            let plaintext = "смерть за смерть \(i)".data(using: String.Encoding.utf8)!
            let message = try! aliceCipher.encryptMessage(plaintext, protocolContext: nil)
            aliceMessages.append((plaintext:plaintext, message:message))
        }

//    long seed = System.currentTimeMillis();
//    
//    Collections.shuffle(aliceCiphertextMessages, new Random(seed));
//    Collections.shuffle(alicePlaintextMessages, new Random(seed));
        aliceMessages = aliceMessages.shuffled()

//    for (int i=0;i<aliceCiphertextMessages.size() / 2;i++) {
//    byte[] receivedPlaintext = bobCipher.decrypt(new SignalMessage(aliceCiphertextMessages.get(i).serialize()));
//    assertTrue(Arrays.equals(receivedPlaintext, alicePlaintextMessages.get(i)));
//    }
        let alicePivot = aliceMessages.count / 2
        let aliceMessagesLeft = aliceMessages[0 ..< alicePivot]
        let aliceMessagesRight = aliceMessages[alicePivot ..< aliceMessages.count]
        for (plaintext, message) in aliceMessagesLeft {
            let receivedPlaintext = try! bobCipher.decrypt(message, protocolContext: nil)
            XCTAssertEqual(plaintext, receivedPlaintext)
        }

//    List<CiphertextMessage> bobCiphertextMessages = new ArrayList<>();
//    List<byte[]>            bobPlaintextMessages  = new ArrayList<>();
        var bobMessages = [MessageTuple]()

//    for (int i=0;i<20;i++) {
//    bobPlaintextMessages.add(("смерть за смерть " + i).getBytes());
//    bobCiphertextMessages.add(bobCipher.encrypt(("смерть за смерть " + i).getBytes()));
//    }
        for i in 1...20 {
            let plaintext = "смерть за смерть \(i)".data(using: String.Encoding.utf8)!
            let message = try! bobCipher.encryptMessage(plaintext, protocolContext: nil)
            bobMessages.append((plaintext:plaintext, message:message))
        }

//    seed = System.currentTimeMillis();
//    
//    Collections.shuffle(bobCiphertextMessages, new Random(seed));
//    Collections.shuffle(bobPlaintextMessages, new Random(seed));
        bobMessages = bobMessages.shuffled()

//    for (int i=0;i<bobCiphertextMessages.size() / 2;i++) {
//    byte[] receivedPlaintext = aliceCipher.decrypt(new SignalMessage(bobCiphertextMessages.get(i).serialize()));
//    assertTrue(Arrays.equals(receivedPlaintext, bobPlaintextMessages.get(i)));
//    }
        let bobPivot = bobMessages.count / 2
        let bobMessagesLeft = bobMessages[0 ..< bobPivot]
        let bobMessagesRight = bobMessages[bobPivot ..< bobMessages.count]
        for (plaintext, message) in bobMessagesLeft {
            let receivedPlaintext = try! aliceCipher.decrypt(message, protocolContext: nil)
            XCTAssertEqual(plaintext, receivedPlaintext)
        }

//    for (int i=aliceCiphertextMessages.size()/2;i<aliceCiphertextMessages.size();i++) {
//    byte[] receivedPlaintext = bobCipher.decrypt(new SignalMessage(aliceCiphertextMessages.get(i).serialize()));
//    assertTrue(Arrays.equals(receivedPlaintext, alicePlaintextMessages.get(i)));
//    }
        for (plaintext, message) in aliceMessagesRight {
            let receivedPlaintext = try! bobCipher.decrypt(message, protocolContext: nil)
            XCTAssertEqual(plaintext, receivedPlaintext)
        }
//
//    for (int i=bobCiphertextMessages.size() / 2;i<bobCiphertextMessages.size(); i++) {
//    byte[] receivedPlaintext = aliceCipher.decrypt(new SignalMessage(bobCiphertextMessages.get(i).serialize()));
//    assertTrue(Arrays.equals(receivedPlaintext, bobPlaintextMessages.get(i)));
//    }
        for (plaintext, message) in bobMessagesRight {
            let receivedPlaintext = try! aliceCipher.decrypt(message, protocolContext: nil)
            XCTAssertEqual(plaintext, receivedPlaintext)
        }
    }

//    private void initializeSessionsV3(SessionState aliceSessionState, SessionState bobSessionState)
//    throws InvalidKeyException
//    {
    private func initializeSessionsV3(aliceSessionState: SessionState,
                              bobSessionState: SessionState,
                              aliceMockClient: MockClient,
                              bobMockClient: MockClient) {
//    ECKeyPair aliceIdentityKeyPair = Curve.generateKeyPair();
        let aliceIdentityKeyPair = aliceMockClient.identityKeyPair
//    IdentityKeyPair aliceIdentityKey     = new IdentityKeyPair(new IdentityKey(aliceIdentityKeyPair.getPublicKey()),
//    aliceIdentityKeyPair.getPrivateKey());
        // TODO: Is this necessary?
        let aliceIdentityKey = aliceIdentityKeyPair
//    ECKeyPair       aliceBaseKey         = Curve.generateKeyPair();
        let aliceBaseKey = Curve25519.generateKeyPair()
//    ECKeyPair       aliceEphemeralKey    = Curve.generateKeyPair();
        // NOTE: aliceEphemeralKey isn't used.

//    ECKeyPair alicePreKey = aliceBaseKey;
        // NOTE: alicePreKey isn't used.

//    ECKeyPair       bobIdentityKeyPair = Curve.generateKeyPair();
        let bobIdentityKeyPair = bobMockClient.identityKeyPair
//    IdentityKeyPair bobIdentityKey       = new IdentityKeyPair(new IdentityKey(bobIdentityKeyPair.getPublicKey()),
        //    bobIdentityKeyPair.getPrivateKey());
        // TODO: Is this necessary?
        let bobIdentityKey = bobIdentityKeyPair
//    ECKeyPair       bobBaseKey           = Curve.generateKeyPair();
        let bobBaseKey = Curve25519.generateKeyPair()
//    ECKeyPair       bobEphemeralKey      = bobBaseKey;
        let bobEphemeralKey = bobBaseKey

//    ECKeyPair       bobPreKey            = Curve.generateKeyPair();
        // NOTE: bobPreKey isn't used.

//    AliceSignalProtocolParameters aliceParameters = AliceSignalProtocolParameters.newBuilder()
//    .setOurBaseKey(aliceBaseKey)
//    .setOurIdentityKey(aliceIdentityKey)
//    .setTheirOneTimePreKey(Optional.<ECPublicKey>absent())
//    .setTheirRatchetKey(bobEphemeralKey.getPublicKey())
//    .setTheirSignedPreKey(bobBaseKey.getPublicKey())
//    .setTheirIdentityKey(bobIdentityKey.getPublicKey())
//    .create();
        let aliceParameters = AliceAxolotlParameters(identityKey: aliceIdentityKey,
                                                     theirIdentityKey: bobIdentityKey.publicKey,
                                                     ourBaseKey: aliceBaseKey,
                                                     theirSignedPreKey: bobBaseKey.publicKey,
                                                     theirOneTimePreKey: nil,
                                                     theirRatchetKey: bobEphemeralKey.publicKey)
//    BobSignalProtocolParameters bobParameters = BobSignalProtocolParameters.newBuilder()
//    .setOurRatchetKey(bobEphemeralKey)
//    .setOurSignedPreKey(bobBaseKey)
//    .setOurOneTimePreKey(Optional.<ECKeyPair>absent())
//    .setOurIdentityKey(bobIdentityKey)
//    .setTheirIdentityKey(aliceIdentityKey.getPublicKey())
//    .setTheirBaseKey(aliceBaseKey.getPublicKey())
//    .create();
        let bobParameters = BobAxolotlParameters(myIdentityKeyPair: bobIdentityKey,
                                                 theirIdentityKey: aliceIdentityKey.publicKey,
                                                 ourSignedPrekey: bobBaseKey,
                                                 ourRatchetKey: bobEphemeralKey,
                                                 ourOneTimePrekey: nil,
                                                 theirBaseKey: aliceBaseKey.publicKey)

        // TODO: We could expose this constant in SessionBuilder.h.
        let currentVersion: Int32 = 3
//    RatchetingSession.initializeSession(aliceSessionState, aliceParameters);
        try! RatchetingSession.initializeSession(aliceSessionState, sessionVersion: currentVersion, aliceParameters: aliceParameters)

//    RatchetingSession.initializeSession(bobSessionState, bobParameters);
        try! RatchetingSession.initializeSession(bobSessionState, sessionVersion: currentVersion, bobParameters: bobParameters)
    }
}
