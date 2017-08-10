function parse_do(ps::ParseState, ret)
    ret = EXPR{Do}(EXPR[ret, INSTANCE(next(ps))], "")

    args = EXPR{TupleH}(EXPR[], "")
    @default ps @closer ps comma @closer ps block while !closer(ps)
        @catcherror ps a = parse_expression(ps)
        push!(args, a)
        if ps.nt.kind == Tokens.COMMA
            next(ps)
            push!(args, INSTANCE(ps))
        end
    end
    push!(ret, args)
    if ps.nt.kind == Tokens.SEMICOLON
        push!(ret.args, INSTANCE(next(ps)))
    end
    block = EXPR{Block}(EXPR[], 0, 1:0, "")
    @catcherror ps @default ps parse_block(ps, block)
    push!(ret, block)

    push!(ret, INSTANCE(next(ps)))
    update_span!(ret)
    return ret
end

parse_kw(ps::ParseState, ::Type{Val{Tokens.IF}}) = parse_if(ps)

"""
    parse_if(ps, ret, nested=false, puncs=[])

Parse an `if` block.
"""
function parse_if(ps::ParseState, nested = false)
    if nested
        ret = EXPR{If}(EXPR[], "")
    else
        ret = EXPR{If}(EXPR[INSTANCE(ps)], "")
    end
    @catcherror ps cond = @default ps @closer ps block @closer ps ws parse_expression(ps)
    push!(ret, cond)
    if ps.nt.kind == Tokens.SEMICOLON
        push!(ret, INSTANCE(next(ps)))
    end

    ifblock = EXPR{Block}(EXPR[], 0, 1:0, "")
    @catcherror ps @default ps @closer ps ifelse parse_block(ps, ifblock, Tokens.Kind[Tokens.END, Tokens.ELSE, Tokens.ELSEIF])
    push!(ret, ifblock)

    elseblock = EXPR{Block}(EXPR[], 0, 1:0, "")
    if ps.nt.kind == Tokens.ELSEIF
        next(ps)
        push!(ret, INSTANCE(ps))

        @catcherror ps push!(elseblock, parse_if(ps, true))
    end
    elsekw = ps.nt.kind == Tokens.ELSE
    if ps.nt.kind == Tokens.ELSE
        next(ps)
        push!(ret, INSTANCE(ps))
        if ps.nt.kind == Tokens.SEMICOLON
            push!(ret, INSTANCE(next(ps)))
        end
        @catcherror ps @default ps parse_block(ps, elseblock)
    end

    # Construction
    !nested && next(ps)
    if !(isempty(elseblock.args) && !elsekw)
        push!(ret, elseblock)
    end
    !nested && push!(ret, INSTANCE(ps))

    return ret
end

function parse_kw(ps::ParseState, ::Type{Val{Tokens.LET}})
    ret = EXPR{Let}(EXPR[INSTANCE(ps)], "")

    @default ps @closer ps comma @closer ps block while !closer(ps)
        @catcherror ps a = parse_expression(ps)
        push!(ret, a)
        if ps.nt.kind == Tokens.COMMA
            next(ps)
            push!(ret, INSTANCE(ps))
        end
    end
    if ps.nt.kind == Tokens.SEMICOLON
        push!(ret, INSTANCE(next(ps)))
    end
    block = EXPR{Block}(EXPR[], 0, 1:0, "")
    @catcherror ps @default ps parse_block(ps, block)
    push!(ret, block)

    push!(ret, INSTANCE(next(ps)))
    return ret
end

function parse_kw(ps::ParseState, ::Type{Val{Tokens.TRY}})
    kw = INSTANCE(ps)
    ret = EXPR{Try}(EXPR[kw], "")
    if ps.nt.kind == Tokens.SEMICOLON
        push!(ret, INSTANCE(next(ps)))
    end

    tryblock = EXPR{Block}(EXPR[], 0, 1:0, "")
    @catcherror ps @default ps @closer ps trycatch parse_block(ps, tryblock,)
    push!(ret, tryblock)

    # try closing early
    if ps.nt.kind == Tokens.END
        next(ps)
        push!(ret, FALSE)
        push!(ret, EXPR{Block}(EXPR[], 0, 1:0, ""))
        push!(ret, INSTANCE(ps))
        return ret
    end

    #  catch block
    if ps.nt.kind == Tokens.CATCH
        next(ps)
        push!(ret, INSTANCE(ps))
        if ps.nt.kind == Tokens.SEMICOLON
            push!(ret, INSTANCE(next(ps)))
        end
        # catch closing early
        if ps.nt.kind == Tokens.FINALLY || ps.nt.kind == Tokens.END
            caught = FALSE
            catchblock = EXPR{Block}(EXPR[], 0, 1:0, "")
        else
            if ps.t.kind == Tokens.SEMICOLON || (ps.ws.kind == NewLineWS)
                caught = FALSE
            else
                @catcherror ps caught = @default ps @closer ps ws @closer ps trycatch parse_expression(ps)
                if ps.nt.kind == Tokens.SEMICOLON
                    push!(ret, INSTANCE(next(ps)))
                end
            end
            catchblock = EXPR{Block}(EXPR[], 0, 1:0, "")
            @catcherror ps @default ps @closer ps trycatch parse_block(ps, catchblock)
            if !(caught isa EXPR{IDENTIFIER} || caught == FALSE)
                unshift!(catchblock, caught)
                caught = FALSE
            end
        end
    else
        caught = FALSE
        catchblock = EXPR{Block}(EXPR[], 0, 1:0, "")
    end
    if last(ret.args) isa EXPR{PUNCTUATION{Tokens.SEMICOLON}}
        insert!(ret.args, length(ret.args), caught)
    else
        push!(ret, caught)
    end
    push!(ret, catchblock)

    # finally block
    if ps.nt.kind == Tokens.FINALLY
        if isempty(catchblock.args)
            ret.args[4] = FALSE
        end
        push!(ret, INSTANCE(next(ps)))
        if ps.nt.kind == Tokens.SEMICOLON
            push!(ret, INSTANCE(next(ps)))
        end
        finallyblock = EXPR{Block}(EXPR[], 0, 1:0, "")
        @catcherror ps parse_block(ps, finallyblock)
        push!(ret, finallyblock)
    end

    next(ps)
    push!(ret, INSTANCE(ps))
    update_span!(ret)
    return ret
end
