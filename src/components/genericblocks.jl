function parse_kw(ps::ParseState, ::Type{T}) where T <: Union{Val{Tokens.BEGIN},Val{Tokens.QUOTE}}
    # Parsing
    kw = INSTANCE(ps)
    ret = EXPR{T == Val{Tokens.BEGIN} ? Begin : Quote}(EXPR[kw], "")
    if ps.nt.kind == Tokens.SEMICOLON
        push!(ret, INSTANCE(next(ps)))
    end
    block = EXPR{Block}(EXPR[], 0, 1:0, "")
    @catcherror ps @default ps parse_block(ps, block, Tokens.Kind[Tokens.END], true)
    push!(ret, block)
    
    push!(ret, INSTANCE(next(ps)))
    return ret
end

"""
    parse_block(ps, ret = EXPR(BLOCK,...))

Parses an array of expressions (stored in ret) until 'end' is the next token.
Returns `ps` the token before the closing `end`, the calling function is
assumed to handle the closer.
"""
function parse_block(ps::ParseState, ret::EXPR{Block}, closers = Tokens.Kind[Tokens.END, Tokens.CATCH, Tokens.FINALLY], docable = false)
    # Parsing
    while !(ps.nt.kind in closers) && !ps.errored
        if docable
            @catcherror ps a = @closer ps block parse_doc(ps)
        else
            @catcherror ps a = @closer ps block parse_expression(ps)
        end
        push!(ret, a)
        if ps.nt.kind == Tokens.SEMICOLON
            push!(ret.args, INSTANCE(next(ps)))
        end
    end
    return ret
end
