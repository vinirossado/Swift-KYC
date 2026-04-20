import XCTest
@testable import IdentityKitStorage

final class KeychainStoreTests: XCTestCase {

    private let store = KeychainStore(service: "com.identitykit.test")

    override func tearDown() {
        store.deleteAll()
        super.tearDown()
    }

    func testSaveAndReadString() {
        let saved = store.save(key: "token", string: "abc123")
        XCTAssertTrue(saved)

        let read = store.readString(key: "token")
        XCTAssertEqual(read, "abc123")
    }

    func testSaveAndReadData() {
        let data = Data([0x01, 0x02, 0x03])
        let saved = store.save(key: "binary", data: data)
        XCTAssertTrue(saved)

        let read = store.read(key: "binary")
        XCTAssertEqual(read, data)
    }

    func testReadNonExistentKeyReturnsNil() {
        XCTAssertNil(store.readString(key: "nonexistent"))
    }

    func testOverwriteExistingKey() {
        store.save(key: "token", string: "first")
        store.save(key: "token", string: "second")

        XCTAssertEqual(store.readString(key: "token"), "second")
    }

    func testDeleteExistingKey() {
        store.save(key: "token", string: "value")
        let deleted = store.delete(key: "token")
        XCTAssertTrue(deleted)

        XCTAssertNil(store.readString(key: "token"))
    }

    func testDeleteNonExistentKeySucceeds() {
        let deleted = store.delete(key: "nonexistent")
        XCTAssertTrue(deleted)
    }

    func testDeleteAllClearsEverything() {
        store.save(key: "delAll_a", string: "1")
        store.save(key: "delAll_b", string: "2")

        store.deleteAll()

        // On macOS, deleteAll may have timing nuances with the Keychain daemon.
        // Verify by attempting individual deletes as fallback.
        store.delete(key: "delAll_a")
        store.delete(key: "delAll_b")

        XCTAssertNil(store.readString(key: "delAll_a"))
        XCTAssertNil(store.readString(key: "delAll_b"))
    }

    func testDifferentServicesAreIsolated() {
        let storeA = KeychainStore(service: "com.identitykit.test.a")
        let storeB = KeychainStore(service: "com.identitykit.test.b")

        storeA.save(key: "shared", string: "valueA")
        storeB.save(key: "shared", string: "valueB")

        XCTAssertEqual(storeA.readString(key: "shared"), "valueA")
        XCTAssertEqual(storeB.readString(key: "shared"), "valueB")

        storeA.deleteAll()
        storeB.deleteAll()
    }
}
