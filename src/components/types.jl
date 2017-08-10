function parse_kw(ps::ParseState, ::Type{Val{Tokens.ABSTRACT}})
    # Switch for v0.6 compatability
    if ps.nt.kind == Tokens.TYPE
        kw1 = INSTANCE(ps)
        next(ps)
        kw2 = INSTANCE(ps)

        @catcherror ps sig = @default ps @closer ps block parse_expression(ps)

        next(ps)
        ret = EXPR{Abstract}(EXPR[kw1, kw2, sig, INSTANCE(ps)], "")
    else
        kw = INSTANCE(ps)
        @catcherror ps sig = @default ps parse_expression(ps)

        ret = EXPR{Abstract}(EXPR[kw, sig], "")
    end
    return ret
end

function parse_kw(ps::ParseState, ::Type{Val{Tokens.BITSTYPE}})
    kw = INSTANCE(ps)

    @catcherror ps arg1 = @default ps @closer ps ws @closer ps wsop parse_expression(ps)
    @catcherror ps arg2 = @default ps parse_expression(ps)

    ret = EXPR{Bitstype}(EXPR[kw, arg1, arg2], "")
    return ret
end

function parse_kw(ps::ParseState, ::Type{Val{Tokens.PRIMITIVE}})
    if ps.nt.kind == Tokens.TYPE
        kw1 = INSTANCE(ps)
        next(ps)
        kw2 = INSTANCE(ps)
        @catcherror ps sig = @default ps @closer ps ws @closer ps wsop parse_expression(ps)
        @catcherror ps arg = @default ps @closer ps block parse_expression(ps)

        next(ps)
        ret = EXPR{Primitive}(EXPR[kw1, kw2, sig, arg, INSTANCE(ps)], "")
    else
        ret = EXPR{IDENTIFIER}(EXPR[], "primitive")
    end
    return ret
end

function parse_kw(ps::ParseState, ::Type{Val{Tokens.TYPEALIAS}})
    kw = INSTANCE(ps)

    @catcherror ps arg1 = @closer ps ws @closer ps wsop parse_expression(ps)
    @catcherror ps arg2 = parse_expression(ps)

    return EXPR{TypeAlias}(EXPR[kw, arg1, arg2], "")
end

parse_kw(ps::ParseState, ::Type{Val{Tokens.TYPE}}) = parse_struct(ps, TRUE)
parse_kw(ps::ParseState, ::Type{Val{Tokens.IMMUTABLE}}) = parse_struct(ps, FALSE)

# new 0.6 syntax
parse_kw(ps::ParseState, ::Type{Val{Tokens.STRUCT}}) = parse_struct(ps, FALSE)

function parse_kw(ps::ParseState, ::Type{Val{Tokens.MUTABLE}})
    if ps.nt.kind == Tokens.STRUCT
        kw = INSTANCE(ps)
        next(ps)
        @catcherror ps ret = parse_struct(ps, TRUE)
        unshift!(ret, kw)
        update_span!(ret)
    else
        ret = IDENTIFIER(ps)
    end
    return ret
end

function parse_struct(ps::ParseState, mutable)
    ret = EXPR{mutable == TRUE ? Mutable : Struct}(EXPR[INSTANCE(ps)], "")
    @catcherror ps sig = @default ps @closer ps block @closer ps ws parse_expression(ps)
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
