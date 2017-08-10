function parse_kw(ps::ParseState, ::Type{Val{Tokens.FOR}})
    # Parsing
    
    ret = EXPR{For}(EXPR[INSTANCE(ps)], "")
    @catcherror ps ranges = @default ps parse_ranges(ps)
    push!(ret, ranges)
    if ps.nt.kind == Tokens.SEMICOLON
        push!(ret, INSTANCE(next(ps)))
    end
    block = EXPR{Block}(EXPR[], 0, 1:0, "")
    @catcherror ps @default ps parse_block(ps, block)
    push!(ret, block)
    push!(ret, INSTANCE(next(ps)))
    update_span!(ret)
    return ret
end


function parse_ranges(ps::ParseState)
    arg = @closer ps range @closer ps comma @closer ps ws parse_expression(ps)
    if ps.nt.kind == Tokens.COMMA
        arg = EXPR{Block}(EXPR[arg], "")
        while ps.nt.kind == Tokens.COMMA
            next(ps)
            push!(arg, INSTANCE(ps))

            @catcherror ps nextarg = @closer ps comma @closer ps ws parse_expression(ps)
            push!(arg, nextarg)
        end
    end
    return arg
end



function parse_kw(ps::ParseState, ::Type{Val{Tokens.WHILE}})
    ret = EXPR{While}(EXPR[INSTANCE(ps)], "")
    @catcherror ps cond = @default ps @closer ps ws parse_expression(ps)
    push!(ret, cond)
    if ps.nt.kind == Tokens.SEMICOLON
        push!(ret, INSTANCE(next(ps)))
    end
    block = EXPR{Block}(EXPR[], 0, 1:0, "")
    @catcherror ps @default ps parse_block(ps, block)
    push!(ret, block)
    push!(ret, INSTANCE(next(ps)))
    update_span!(ret)
    return ret
end

function parse_kw(ps::ParseState, ::Type{Val{Tokens.BREAK}})
    return EXPR{Break}(EXPR[INSTANCE(ps)], "")
end

function parse_kw(ps::ParseState, ::Type{Val{Tokens.CONTINUE}})
    return EXPR{Continue}(EXPR[INSTANCE(ps)], "")
end


"""
parse_generator(ps)

Having hit `for` not at the beginning of an expression return a generator.
Comprehensions are parsed as SQUAREs containing a generator.
"""
function parse_generator(ps::ParseState, ret)
    next(ps)
    kw = INSTANCE(ps)
    ret = EXPR{Generator}(EXPR[ret, kw], "")
    @catcherror ps ranges = @closer ps paren @closer ps square parse_ranges(ps)

    if ps.nt.kind == Tokens.IF
        if ranges isa EXPR{Block}
            ranges = EXPR{Filter}(EXPR[ranges.args...], "")
        else
            ranges = EXPR{Filter}(EXPR[ranges], "")
        end
        next(ps)
        unshift!(ranges, INSTANCE(ps))
        @catcherror ps cond = @closer ps paren parse_expression(ps)
        unshift!(ranges, cond)
        push!(ret, ranges)
    else
        if ranges isa EXPR{Block}
            append!(ret, ranges)
        else
            push!(ret, ranges)
        end
    end

    # This should reverse order of iterators
    if ret.args[1] isa EXPR{Generator} || ret.args[1] isa EXPR{Flatten}
        ret = EXPR{Flatten}(EXPR[ret], "")
    end

    return ret
end
