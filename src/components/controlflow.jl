function parse_do(ps::ParseState, ret)
    # Parsing
    next(ps)
    kw = INSTANCE(ps)

    args = EXPR{TupleH}(Any[])
    @default ps @closer ps comma @closer ps block while !closer(ps)
        @catcherror ps a = parse_expression(ps)

        push!(args, a)
        if ps.nt.kind == Tokens.COMMA
            next(ps)
            push!(args, INSTANCE(ps))
        end
    end

    blockargs = Any[]
    @catcherror ps @default ps parse_block(ps, blockargs)

    return EXPR{Do}(Any[ret, kw, args, EXPR{Block}(blockargs), INSTANCE(next(ps))])
end

parse_kw(ps::ParseState, ::Type{Val{Tokens.IF}}) = parse_if(ps)

"""
    parse_if(ps, ret, nested=false, puncs=[])

Parse an `if` block.
"""
function parse_if(ps::ParseState, nested = false)
    # Parsing
    kw = INSTANCE(ps)
    @catcherror ps cond = @default ps @closer ps block @closer ps ws parse_expression(ps)

    
    ifblockargs = Any[]
    @catcherror ps @default ps @closer ps ifelse parse_block(ps, ifblockargs, (Tokens.END, Tokens.ELSE, Tokens.ELSEIF))

    if nested
        ret = EXPR{If}(Any[cond, EXPR{Block}(ifblockargs)])
    else
        ret = EXPR{If}(Any[kw, cond, EXPR{Block}(ifblockargs)])
    end

    elseblock = EXPR{Block}(Any[], 0, 1:0)
    if ps.nt.kind == Tokens.ELSEIF
        next(ps)
        push!(ret, INSTANCE(ps))

        @catcherror ps push!(elseblock, parse_if(ps, true))
    end
    elsekw = ps.nt.kind == Tokens.ELSE
    if ps.nt.kind == Tokens.ELSE
        next(ps)
        push!(ret, INSTANCE(ps))
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
    args = Any[INSTANCE(ps)]
    @default ps @closer ps comma @closer ps block while !closer(ps)
        @catcherror ps a = parse_expression(ps)
        push!(args, a)
        if ps.nt.kind == Tokens.COMMA
            next(ps)
            push!(args, INSTANCE(ps))
        end
    end
    
    blockargs = Any[]
    @catcherror ps @default ps parse_block(ps, blockargs)

    push!(args, EXPR{Block}(blockargs))
    push!(args, INSTANCE(next(ps)))

    return EXPR{Let}(args)
end

function parse_kw(ps::ParseState, ::Type{Val{Tokens.TRY}})
    kw = INSTANCE(ps)
    ret = EXPR{Try}(Any[kw])

    tryblockargs = Any[]
    @catcherror ps @default ps @closer ps trycatch parse_block(ps, tryblockargs, (Tokens.END, Tokens.CATCH, Tokens.FINALLY))
    push!(ret, EXPR{Block}(tryblockargs))

    # try closing early
    if ps.nt.kind == Tokens.END
        next(ps)
        push!(ret, FALSE)
        push!(ret, EXPR{Block}(Any[], 0, 1:0))
        push!(ret, INSTANCE(ps))
        return ret
    end

    #  catch block
    if ps.nt.kind == Tokens.CATCH
        next(ps)
        # catch closing early
        if ps.nt.kind == Tokens.FINALLY || ps.nt.kind == Tokens.END
            push!(ret, INSTANCE(ps))
            caught = FALSE
            catchblock = EXPR{Block}(Any[], 0, 1:0)
        else
            start_col = ps.t.startpos[2] + 4
            push!(ret, INSTANCE(ps))
            if ps.ws.kind == SemiColonWS || ps.ws.kind == NewLineWS
                caught = FALSE
            else
                @catcherror ps caught = @default ps @closer ps ws @closer ps trycatch parse_expression(ps)
            end
            catchblock = EXPR{Block}(Any[], 0, 1:0)
            @catcherror ps @default ps @closer ps trycatch parse_block(ps, catchblock, (Tokens.END, Tokens.FINALLY))
            if !(caught isa IDENTIFIER || caught == FALSE)
                unshift!(catchblock, caught)
                caught = FALSE
            end
        end
    else
        caught = FALSE
        catchblock = EXPR{Block}(Any[], 0, 1:0)
    end
    push!(ret, caught)
    push!(ret, catchblock)

    # finally block
    if ps.nt.kind == Tokens.FINALLY
        if isempty(catchblock.args)
            ret.args[4] = FALSE
        end
        next(ps)
        push!(ret, INSTANCE(ps))
        finallyblock = EXPR{Block}(Any[], 0, 1:0)
        @catcherror ps parse_block(ps, finallyblock)
        push!(ret, finallyblock)
    end

    next(ps)
    push!(ret, INSTANCE(ps))
    return ret
end
