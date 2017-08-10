function parse_kw(ps::ParseState, ::Type{Val{Tokens.MACRO}})
    ret = EXPR{Macro}(EXPR[INSTANCE(ps)], "")
    if ps.nt.kind == Tokens.IDENTIFIER
        next(ps)
        sig = INSTANCE(ps)
        @catcherror ps sig = parse_call(ps, sig)
    else
        @catcherror ps sig = @closer ps block @closer ps ws parse_expression(ps)
    end
    push!(ret, sig)
    if ps.nt.kind == Tokens.SEMICOLON
        push!(ret, INSTANCE(next(ps)))
    end

    block = EXPR{Block}(EXPR[], 0, 1:0, "")
    @catcherror ps @default ps parse_block(ps, block)
    push!(ret, block)
    push!(ret, INSTANCE(next(ps)))
    
    return ret
end

"""
    parse_macrocall(ps)

Parses a macro call. Expects to start on the `@`.
"""
function parse_macrocall(ps::ParseState)
    next(ps)
    mname = IDENTIFIER(ps)
    mname = EXPR{IDENTIFIER}(EXPR[], 1 + mname.fullspan, 1:(last(mname.span) + 1), string("@", ps.t.val))
    # Handle cases with @ at start of dotted expressions
    if ps.nt.kind == Tokens.DOT && isemptyws(ps.ws)
        while ps.nt.kind == Tokens.DOT
            next(ps)
            op = INSTANCE(ps)
            if ps.nt.kind != Tokens.IDENTIFIER
                return EXPR{ERROR}(EXPR[], 0, 1:0, "Invalid macro name")
            end
            next(ps)
            nextarg = INSTANCE(ps)
            mname = EXPR{BinarySyntaxOpCall}(EXPR[mname, op, Quotenode(nextarg)], "")
        end
    end
    ret = EXPR{MacroCall}(EXPR[mname], "")

    if ps.nt.kind == Tokens.COMMA
        return ret
    end
    if isemptyws(ps.ws) && ps.nt.kind == Tokens.LPAREN
        next(ps)
        push!(ret, INSTANCE(ps))
        @catcherror ps @default ps @nocloser ps newline @closer ps paren parse_comma_sep(ps, ret, false)
        next(ps)
        push!(ret, INSTANCE(ps))
    else
        insquare = ps.closer.insquare
        @default ps while !closer(ps)
            @catcherror ps a = @closer ps inmacro @closer ps ws @closer ps wsop parse_expression(ps)
            push!(ret, a)
            if insquare && ps.nt.kind == Tokens.FOR
                break
            end
        end
    end
    return ret
end


ismacro(x) = false
ismacro(x::EXPR{LITERAL{Tokens.MACRO}}) = true
ismacro(x::EXPR{Quotenode}) = ismacro(x.args[1])
function ismacro(x::EXPR{BinarySyntaxOpCall})
    if x.args[2] isa OPERATOR{DotOp,Tokens.DOT}
        return ismacro(x.args[2])
    else
        return false
    end
end
