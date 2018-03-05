import Lexer
import Source

class Parser<ResultType> {

    let sourceFile: SourceFile
     let lexer: Lexer // TODO: make private

    init(lexer: Lexer, sourceFile: SourceFile) {
        self.lexer = lexer
        self.sourceFile = sourceFile
    }

    func parse() -> ResultType? {
        fatalError("override me")
    }

    func convert(_ location: SourceLocation) -> Int64? {
        let zeroBasedColumn = location.column - 1
        return LocationConverter.convert(line: location.line, column: zeroBasedColumn, in: sourceFile.content)!
    }

    func getCurrentStartLocation() -> SourceLocation {
        return getCurrentRange().start
    }

    func getCurrentEndLocation() -> SourceLocation {
        return getCurrentRange().end
    }

    func getCurrentRange() -> SourceRange {
        return lexer.look().sourceRange
    }

    func getLength(_ string: String) -> Int64 {
        return Int64(string.utf8.count)
    }

    func peekAtNextIdentifier() -> String? {
        return lexer.look().kind.namedIdentifier
    }

    func isNext(_ kind: Token.Kind) -> Bool {
        return lexer.look().kind == kind
    }

    func advance() {
        lexer.advance()
    }

    func advance(if kind: Token.Kind) {
        if isNext(kind) {
            advance()
        }
    }

    func parseInheritanceClause() -> [NamedElement]? {
        return InheritanceClauseParser(lexer: lexer, sourceFile: sourceFile).parse()
    }

    func parseInheritanceType() -> NamedElement? {
        return TypeIdentifierParser(lexer: lexer, sourceFile: sourceFile).parse()
    }

    func parseTypeCodeBlock() -> CodeBlock? {
        return CodeBlockParser(lexer: lexer, sourceFile: sourceFile).parse()
    }

    func parseDeclarations() -> [Element] {
        let start = getCurrentStartLocation()
        var elements = [Element]()
        if isNext(.protocol) {
            advance()
            parseProtocol(start: start).map { elements.append($0) }
        }
        return elements
    }

    func parseProtocol(start: SourceLocation) -> Element? {
        let offset = convert(start)!
        guard let name = peekAtNextIdentifier() else { return nil }
        advance()
        if let inheritanceClause = parseInheritanceClause(),
           let (bodyOffset, bodyLength, bodyEnd, declarations) = parseTypeCodeBlock() {
            let length = bodyEnd - offset
            let text = getSubstring(from: sourceFile.content, offset: offset, length: length)!
            return SwiftTypeElement(
                name: name,
                text: text,
                children: declarations,
                inheritedTypes: inheritanceClause,
                offset: offset,
                length: length,
                bodyOffset: bodyOffset,
                bodyLength: bodyLength)
        }
        return nil
    }
}