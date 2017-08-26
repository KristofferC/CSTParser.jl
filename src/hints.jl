module Diagnostics

abstract type Format end
abstract type Lint end
abstract type Action end

mutable struct Diagnostic{C}
    loc::UnitRange
    actions::Vector{Action}
    message::String
end
Diagnostic(r::UnitRange) = Diagnostic(r, [], "")

@enum(ErrorCodes,
UnexpectedLParen,
UnexpectedRParen,
UnexpectedLBrace,
UnexpectedRBrace,
UnexpectedLSquare,
UnexpectedRSquare,
UnexpectedInputEnd,
UnexpectedComma,
UnexpectedOperator,
UnexpectedIdentifier,
ParseFailure)

@enum(LintCodes,
DuplicateArgumentName,
ArgumentFunctionNameConflict,
SlurpingPosition,
KWPosition,
ImportInFunction,
DuplicateArgument,
LetNonAssignment,
RangeNonAssignment,
CondAssignment,
DeadCode,
DictParaMisSpec,
DictGenAssignment,
MisnamedConstructor,
LoopOverSingle,
AssignsToFuncName,
PossibleTypo,

Deprecation,
functionDeprecation,
typeDeprecation,
immutableDeprecation,
abstractDeprecation,
bitstypeDeprecation,
typealiasDeprecation,
parameterisedDeprecation)


end


function error_unexpected(ps, startbyte, tok)
    if tok.kind == Tokens.ENDMARKER
        ps.errored = true
        push!(ps.diagnostics, Diagnostic{Diagnostics.UnexpectedInputEnd}(
            tok.startbyte:tok.endbyte, [], "Unexpected end of input"
        ))
        return EXPR{ERROR}(Any[INSTANCE(ps)])
    elseif tok.kind == Tokens.COMMA
        ps.errored = true
        push!(ps.diagnostics, Diagnostic{Diagnostics.UnexpectedComma}(
            tok.startbyte:tok.endbyte, [], "Unexpected comma"
        ))
        return EXPR{ERROR}(Any[INSTANCE(ps)])
    elseif tok.kind == Tokens.LPAREN
        ps.errored = true
        push!(ps.diagnostics, Diagnostic{Diagnostics.UnexpectedLParen}(
            tok.startbyte:tok.endbyte, [], "Unexpected ("
        ))
        return EXPR{ERROR}(Any[INSTANCE(ps)])
    elseif tok.kind == Tokens.RPAREN
        ps.errored = true
        push!(ps.diagnostics, Diagnostic{Diagnostics.UnexpectedRParen}(
            tok.startbyte:tok.endbyte, [], "Unexpected )"
        ))
        return EXPR{ERROR}(Any[INSTANCE(ps)])
    elseif tok.kind == Tokens.LBRACE
        ps.errored = true
        push!(ps.diagnostics, Diagnostic{Diagnostics.UnexpectedLBrace}(
            tok.startbyte:tok.endbyte, [], "Unexpected {"
        ))
        return EXPR{ERROR}(Any[INSTANCE(ps)])
    elseif tok.kind == Tokens.RBRACE
        ps.errored = true
        push!(ps.diagnostics, Diagnostic{Diagnostics.UnexpectedRBrace}(
            tok.startbyte:tok.endbyte, [], "Unexpected }"
        ))
        return EXPR{ERROR}(Any[INSTANCE(ps)])
    elseif tok.kind == Tokens.LSQUARE
        ps.errored = true
        push!(ps.diagnostics, Diagnostic{Diagnostics.UnexpectedLSquare}(
            tok.startbyte:tok.endbyte, [], "Unexpected ["
        ))
        return EXPR{ERROR}(Any[INSTANCE(ps)])
    elseif tok.kind == Tokens.RSQUARE
        ps.errored = true
        push!(ps.diagnostics, Diagnostic{Diagnostics.UnexpectedRSquare}(
            tok.startbyte:tok.endbyte, [], "Unexpected ]"
        ))
        return EXPR{ERROR}(Any[INSTANCE(ps)])
    else
        error("Internal error")
    end
end
