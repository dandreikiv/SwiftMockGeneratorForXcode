class GenericParameterClauseParser: Parser<GenericParameterClause> {

    override func parse(start: LineColumn) -> GenericParameterClause {
        guard isNext("<") else {
            return GenericParameterClauseImpl.emptyGenericParameterClause
        }
        advanceOperator("<")
        let parameters = parseGenericParameterList()
        parseGenericClosingBracket()
        return createElement(start: start) { offset, length, text in
            return GenericParameterClauseImpl(
                text: text,
                children: parameters,
                offset: offset,
                length: length,
                parameters: parameters)
        } ?? GenericParameterClauseImpl.errorGenericParameterClause
    }

    private func parseGenericParameterList() -> [GenericParameter] {
        var parameterList = [GenericParameter]()
        repeat {
            advance(if: .comma)
            parameterList.append(parseGenericParameter())
        } while isNext(.comma)
        return parameterList
    }

    private func parseGenericParameter() -> GenericParameter {
        let offset = getCurrentStartLocation()
        guard let typeName = peekAtNextIdentifier() else {
            return GenericParameterImpl.errorGenericParameter
        }
        advance()
        advance(if: .colon)
        let type = parseType()
        let typeIdentifier = type as? TypeIdentifier
        let protocolComposition = type as? ProtocolCompositionType
        let children = [typeIdentifier as Element?, protocolComposition as Element?].compactMap { $0 }
        return createElement(start: offset) { offset, length, text in
            return GenericParameterImpl(text: text,
                    children: children,
                    offset: offset,
                    length: length,
                    typeName: typeName,
                    typeIdentifier: typeIdentifier,
                    protocolComposition: protocolComposition)
        }!
    }

    private func parseGenericClosingBracket() {
        if isNext(">") {
            advanceOperator(">")
        }
    }
}
