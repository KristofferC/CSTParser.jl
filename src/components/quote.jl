function parse_kw(ps::ParseState, ::Type{Val{Tokens.QUOTE}})
    # Parsing
    kw = INSTANCE(ps)
    format_kw(ps)
    arg = EXPR{Block}(EXPR[], 0, 1:0, "")
    @catcherror ps @default ps parse_block(ps, arg)
    next(ps)

    # Construction
    ret = EXPR{Quote}(EXPR[kw, arg, INSTANCE(ps)], "")

    return ret
end
