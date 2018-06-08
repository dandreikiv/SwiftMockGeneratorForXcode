class ElementWrapper: Element {

    private let managed: Element

    var text: String {
        return managed.text
    }

    var children: [Element] {
        return managed.children
    }

    var file: File? {
        return managed.file
    }

    var parent: Element? {
        return managed.parent
    }

    var offset: Int64 {
        return managed.offset
    }

    var length: Int64 {
        return managed.length
    }

    public init(_ element: Element) {
        self.managed = element
        retainManagedFile(element: element)
    }

    private func retainManagedFile(element: Element) {
        let file = element.file as? SwiftFile
        file?.retainCount += 1
    }

    deinit {
        releaseManagedFile()
    }

    private func releaseManagedFile() {
        let file = self.file as? SwiftFile
        file?.retainCount -= 1
        if file?.retainCount == 0 {
            let visitor = BreakRetainCycleVisitor()
            file?.accept(visitor)
        }
    }

    private class BreakRetainCycleVisitor: RecursiveElementVisitor {

        override func visitElement(_ element: Element) {
            (element as? ElementImpl)?.file = nil
            super.visitElement(element)
        }
    }

    func accept(_ visitor: ElementVisitor) {
        managed.accept(visitor)
    }
}
