class ParameterParser: Parser<Parameter> {

    override func parse() throws -> Parameter {
        if isNext(.eof) {
            throw LookAheadError()
        }
        return try ParameterImpl(children: builder()
                .optional { try self.parsePunctuation(.underscore) }
                .optional { try self.parseParameterIdentifier() }
                .optional { try self.parseParameterIdentifier() }
                .optional { try self.parseTypeAnnotation() }
                .either({ try self.parseVarArgs() }) {
                    try self.parseDefaultArgumentClause()
                }
                .build())
    }

    private func parseParameterIdentifier() throws -> Element {
        if let identifier = try? parseIdentifier() {
            return identifier
        } else if case let .booleanLiteral(bool) = peekAtNextKind() {
            advance()
            let identifier = IdentifierImpl(text: String(describing: bool))
            return identifier
        } else {
            let keyword = try parseKeyword()
            if keyword.text != "" {
                return IdentifierImpl(text: keyword.text)
            }
        }
        throw LookAheadError()
    }
}
