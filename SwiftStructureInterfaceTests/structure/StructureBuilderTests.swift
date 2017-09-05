import XCTest
import SourceKittenFramework
@testable import SwiftStructureInterface

class StructureBuilderTests: XCTestCase {

    // MARK: - build

    func test_build_shouldBuildProtocolFromDictionary() {
        let file = StructureBuilderTestHelper.build(from: getProtocolString())
        let element = file?.children.first as? SwiftTypeElement
        XCTAssertEqual(element?.name, "Protocol")
        XCTAssertEqual(element?.inheritedTypes.count, 1)
        XCTAssertEqual(element?.inheritedTypes[0].name, "Inherited")
        XCTAssertEqual(element?.children.count, 2)
        XCTAssertEqual(element?.children[0].name, "property")
        XCTAssertEqual(element?.children[1].name, "method")
        XCTAssert(element?.file === file)
        XCTAssert(element?.children[0].file === file)
        XCTAssert(element?.children[1].file === file)
    }

    func test_build_shouldPopulateOffsets() {
        let file = StructureBuilderTestHelper.build(from: getProtocolString())
        let element = file?.children.first as? SwiftTypeElement
        XCTAssertEqual(element?.offset, 0)
        XCTAssertEqual(element?.length, getProtocolLength())
        XCTAssertEqual(element?.bodyOffset, getProtocolBodyOffset())
        XCTAssertEqual(element?.bodyLength, getProtocolBodyLength())
    }

    func test_build_shouldBuildClassFromDictionary() {
        let file = StructureBuilderTestHelper.build(from: getClassString())
        let element = file?.children.first as? SwiftTypeElement
        XCTAssertEqual(element?.name, "A")
        XCTAssertEqual(element?.inheritedTypes.count, 1)
        XCTAssertEqual(element?.inheritedTypes[0].name, "B")
        XCTAssertEqual(element?.children.count, 5)
        XCTAssertEqual(element?.children[0].name, "varA")
        XCTAssertEqual(element?.children[1].name, "varB")
        XCTAssertEqual(element?.children[2].name, "varC")
        XCTAssertEqual(element?.children[3].name, "methodA")
        XCTAssertEqual(element?.children[4].name, "methodB")
        XCTAssertEqual(file?.text, getClassString())
    }

    func test_build_shouldBuildNestedClassFromDictionary() {
        let file = StructureBuilderTestHelper.build(from: getNestedClassString())
        let element = file?.children.first as? SwiftTypeElement
        XCTAssertEqual(element?.name, "A")
        XCTAssertEqual(element?.inheritedTypes.count, 0)
        XCTAssertEqual(element?.children.count, 2)
        XCTAssertEqual(element?.children[1].name, "methodA")
        let innerElement = element?.children[0] as? SwiftTypeElement
        XCTAssertEqual(innerElement?.name, "B")
        XCTAssertEqual(innerElement?.inheritedTypes.count, 2)
        XCTAssertEqual(innerElement?.inheritedTypes[0].name, "C")
        XCTAssertEqual(innerElement?.inheritedTypes[1].name, "D")
        XCTAssertEqual(innerElement?.children.count, 1)
        XCTAssertEqual(innerElement?.children[0].name, "innerMethodA")
        XCTAssertEqual(file?.text, getNestedClassString())
    }

    func test_build_shouldSetTextOnElements() {
        let file = StructureBuilderTestHelper.build(from: getProtocolString())
        let `protocol` = file?.children.first as? SwiftTypeElement
        let inheritedType = `protocol`?.inheritedTypes.first
        let property = `protocol`?.children[0]
        let method = `protocol`?.children[1]
        XCTAssertEqual(file?.text, getProtocolString())
        XCTAssertEqual(`protocol`?.text, getProtocolString())
        XCTAssertEqual(inheritedType?.text, "Inherited")
        XCTAssertEqual(property?.text, "var property: String { get set }")
        XCTAssertEqual(method?.text, "func method()")
    }

    // These are missing in SourceKit
    func test_build_shouldCalculateOffsetsForInheritedTypes() {
        let file = StructureBuilderTestHelper.build(from: getInheritedTypesExampleString())
        let `protocol` = file?.children.first as? SwiftTypeElement
        let simpleType = `protocol`?.inheritedTypes[0]
        XCTAssertEqual(simpleType?.offset, 19)
        XCTAssertEqual(simpleType?.length, 19)
        XCTAssertEqual(simpleType?.text, "SimpleInheritedType")
        let genericType = `protocol`?.inheritedTypes[1]
        XCTAssertEqual(genericType?.offset, 40)
        XCTAssertEqual(genericType?.length, 15)
        XCTAssertEqual(genericType?.text, "Generic<String>")
        let snakeCaseType = `protocol`?.inheritedTypes[2]
        XCTAssertEqual(snakeCaseType?.offset, 60)
        XCTAssertEqual(snakeCaseType?.length, 10)
        XCTAssertEqual(snakeCaseType?.text, "snake_case")
    }

    func test_build_shouldCalculateOffsetsForInheritedTypes_whenUTF16CharactersArePresent() {
        // "💐".utf8.count = 4
        // SourceKit doesn't seem to support inherited types with emojis in their name.
        print(UnicodeScalar(0x2D30)!)
        let string = "protocol 💐Protocol: Type1 { }"
        let file = StructureBuilderTestHelper.build(from: string)
        let `protocol` = file?.children.first as? SwiftTypeElement
        let type1 = `protocol`?.inheritedTypes[0]
        XCTAssertEqual(type1?.offset, 23)
        XCTAssertEqual(type1?.length, 5)
        XCTAssertEqual(type1?.text, "Type1")
    }

    func test_build_shouldBuildWithNoInheritedTypes() {
        let file = StructureBuilderTestHelper.build(from: getNoInheritedTypesExampleString())
        let element = file?.children[0] as! SwiftTypeElement
        XCTAssert(element.inheritedTypes.isEmpty)
    }

    func test_build_shouldNotConfusePartiallyMatchingStringsInClassNameAndInheritedTypes() {
        let file = StructureBuilderTestHelper.build(from: getRealisticNameExampleString())
        let element = file?.children[0] as! SwiftTypeElement
        let inheritedType = element.inheritedTypes[0]
        XCTAssertEqual(element.name, "MockProtocol")
        XCTAssertEqual(inheritedType.name, "Protocol")
        XCTAssertEqual(inheritedType.offset, 20)
        XCTAssertEqual(inheritedType.length, 8)
    }

    func test_build_shouldFindInheritedTypesOnNewlines() {
        let file = StructureBuilderTestHelper.build(from: getNewlineTypesExampleString())
        let element = file?.children[0] as! SwiftTypeElement
        let inheritedType = element.inheritedTypes[0]
        let inheritedType2 = element.inheritedTypes[1]
        XCTAssertEqual(element.name, "AClass")
        XCTAssertEqual(inheritedType.name, "ProtocolA")
        XCTAssertEqual(inheritedType.offset, 14)
        XCTAssertEqual(inheritedType.length, 9)
        XCTAssertEqual(inheritedType2.name, "Prot")
        XCTAssertEqual(inheritedType2.offset, 26)
        XCTAssertEqual(inheritedType2.length, 4)
    }

    func test_build_shouldFindMultipleTypesInBaseOfFile() {
        let file = StructureBuilderTestHelper.build(from: getMultipleTypeExampleString())
        let firstType = file?.children[0] as! SwiftTypeElement
        XCTAssertEqual(firstType.name, "ProtocolA")
        let secondType = file?.children[1] as! SwiftTypeElement
        let inheritedType = secondType.inheritedTypes[0]
        XCTAssertEqual(secondType.name, "ClassA")
        XCTAssertEqual(inheritedType.name, "ProtocolA")
        XCTAssertEqual(inheritedType.offset, 37)
        XCTAssertEqual(inheritedType.length, 9)
    }

    func test_build_shouldNotCrash_whenStringIsSmallerThanTheDataProvided() {
        _ = StructureBuilder(data: Structure(file: File(contents: getProtocolString())).dictionary, text: "").build() // should not crash
    }

    func test_build_shouldDetectMethods() {
        let file = StructureBuilderTestHelper.build(from: getMethodsExampleString())!
        let protocolType = file.children[0] as! SwiftTypeElement
        let protocolMethod = protocolType.children[0] as? SwiftMethodElement
        XCTAssertEqual(protocolMethod?.name, "protocolMethod")
        let classType = file.children[1] as! SwiftTypeElement
        let instanceMethod = classType.children[0] as? SwiftMethodElement
        XCTAssertEqual(instanceMethod?.name, "method")
        let nestedMethod = instanceMethod?.children[0] as? SwiftMethodElement
        XCTAssertEqual(nestedMethod?.name, "nestedMethod")
        let classMethod = classType.children[1] as? SwiftMethodElement
        XCTAssertEqual(classMethod?.name, "classMethod")
        let staticMethod = classType.children[2] as? SwiftMethodElement
        XCTAssertEqual(staticMethod?.name, "staticMethod")
    }

    // MARK: - Helpers

    private func getProtocolString() -> String {
        return "protocol Protocol: Inherited {" + "\n" +
            "    " + "\n" +
            "    var property: String { get set }" + "\n" +
            "    " + "\n" +
            "    func method()" + "\n" +
            "}"
    }

    private func getProtocolLength() -> Int64 {
        return Int64(getProtocolString().utf8.count)
    }

    private func getProtocolBodyOffset() -> Int64 {
        return 30
    }

    private func getProtocolBodyLength() -> Int64 {
        let endCurlyBrace: Int64 = 1
        return getProtocolLength() - getProtocolBodyOffset() - endCurlyBrace
    }

    private func getClassString() -> String {
        return "class A: B {" + "\n" +
            "    " + "\n" +
            "    var varA: String = \"varAResult\"" + "\n" +
            "    var varB: String {" + "\n" +
            "        return \"varBResult\"" + "\n" +
            "    }" + "\n" +
            "    var varC: String {" + "\n" +
            "        set {" + "\n" +
            "            " + "\n" +
            "        }" + "\n" +
            "        get {" + "\n" +
            "            return \"varCResult\"" + "\n" +
            "        }" + "\n" +
            "    }" + "\n" +
            "    " + "\n" +
            "    func methodA() -> String {" + "\n" +
            "        return \"methodAResult\"" + "\n" +
            "    }" + "\n" +
            "    " + "\n" +
            "    func methodB(labelA nameA: String, labelB: String) {" + "\n" +
            "        var methodVarA = \"methodVarAResult\"" + "\n" +
            "    }" + "\n" +
            "}"
    }

    private func getNestedClassString() -> String {
        return "class A {" + "\n" +
            "    " + "\n" +
            "    class B: C, D {" + "\n" +
            "" + "\n" +
            "        func innerMethodA() {}" + "\n" +
            "    }" + "\n" +
            "" + "\n" +
            "    func methodA() {}" + "\n" +
            "}"
    }

    private func getInheritedTypesExampleString() -> String {
        return "protocol Protocol: SimpleInheritedType, Generic<String>  ,  snake_case {" + "\n" +
            "" + "\n" +
            "}"
    }

    private func getNoInheritedTypesExampleString() -> String {
        return "protocol Protocol {" + "\n" +
            "" + "\n" +
            "}"
    }

    private func getRealisticNameExampleString() -> String {
        return "class MockProtocol: Protocol {" + "\n" +
            "" + "\n" +
            "}"
    }

    private func getNewlineTypesExampleString() -> String {
        return "class AClass: ProtocolA ," + "\n" +
            "Prot" + "\n" +
            "{" + "\n" +
            "}"
    }

    private func getMultipleTypeExampleString() -> String {
        return "protocol ProtocolA {}" + "\n" +
            "" + "\n" +
            "class ClassA: ProtocolA {}"
    }

    private func getMethodsExampleString() -> String {
        return "protocol TestProtocol {" + "\n" +
            "  func protocolMethod()" + "\n" +
            "}" + "\n" +
            "" + "\n" +
            "class TestClass {" + "\n" +
            "  func method() {" + "\n" +
            "    func nestedMethod() {}" + "\n" +
            "  }" + "\n" +
            "  class func classMethod() {}" + "\n" +
            "  static func staticMethod() {}" + "\n" +
            "}" + "\n" +
            "" + "\n" +
            "func globalMethod() {}"
    }
}