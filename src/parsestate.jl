import Tokenize.Lexers: peekchar, prevchar, readchar, iswhitespace, emit, emit_error, backup!, accept_batch, eof

typealias EmptyWS Tokens.begin_delimiters
typealias NewLineWS Tokens.begin_literal
typealias WS Tokens.end_literal

type Closer
    toplevel::Bool
    newline::Bool
    eof::Bool
    tuple::Bool
    comma::Bool
    dot::Bool
    paren::Bool
    quotemode::Bool
    brace::Bool
    square::Bool
    block::Bool
    ifelse::Bool
    ifop::Bool
    trycatch::Bool
    ws::Bool
    precedence::Int
end

Closer() = Closer(true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, 0)

type Scope{t}
    id
    args::Vector
end

type Variable
    id
    t
end

type ParseState
    l::Lexer
    done::Bool
    lt::Token
    t::Token
    nt::Token
    lws::Token
    ws::Token
    nws::Token
    formatcheck::Bool
    ids::Dict{String,Any}
    hints::Vector{Any}
    closer::Closer
    current_scope::Scope
end
function ParseState(str::String)
    next(ParseState(tokenize(str), false, Token(), Token(), Token(), Token(), Token(), Token(), true, Dict(), [], Closer(), Scope{Tokens.TOPLEVEL}(TOPLEVEL, [])))
end

function Base.show(io::IO, ps::ParseState)
    println(io, "ParseState $(ps.done ? "finished " : "")at $(position(ps.l.io))")
    println(io,"last    : ", ps.lt.kind, " ($(ps.lt))", "    ($(wstype(ps.lws)))")
    println(io,"current : ", ps.t.kind, " ($(ps.t))", "    ($(wstype(ps.ws)))")
    println(io,"next    : ", ps.nt.kind, " ($(ps.nt))", "    ($(wstype(ps.nws)))")
end
peekchar(ps::ParseState) = peekchar(ps.l)
wstype(t::Token) = t.kind == Tokens.begin_delimiters ? "empty" :
                   t.kind == Tokens.begin_literal ? "ws w/ newline" : "ws"

function next(ps::ParseState)
    ps.lt = ps.t
    ps.t = ps.nt
    ps.lws = ps.ws
    ps.ws = ps.nws
    ps.nt, ps.done  = next(ps.l, ps.done)
    if iswhitespace(peekchar(ps.l)) || peekchar(ps.l)=='#'
        ps.nws = lex_ws_comment(ps.l, readchar(ps.l))
    else
        ps.nws = Token(EmptyWS, (0, 0), (0, 0), ps.nt.endbyte, ps.nt.endbyte, "")
    end
    return ps
end

function lex_ws_comment(l::Lexer, c)
    newline = c=='\n'
    if c=='#'
        newline = read_comment(l)
    else
        newline = read_ws(l, newline)
    end
    while iswhitespace(peekchar(l)) || peekchar(l)=='#'
        c = readchar(l)
        if c=='#'
            read_comment(l)
            newline = peekchar(l)=='\n'
        else
            newline = read_ws(l, newline)
        end
    end

    return emit(l, newline ? NewLineWS : WS)
end



function read_ws(l::Lexer, ok)
    while iswhitespace(peekchar(l))
        readchar(l)=='\n' && (ok = true)
    end
    return ok
end

function read_comment(l::Lexer)
    if readchar(l) != '='
        while true
            c = readchar(l)
            if c == '\n' || eof(c)
                backup!(l)
                break
            end
        end
    else
        c = readchar(l) # consume the '='
        n_start, n_end = 1, 0
        while true
            if eof(c)
                return emit_error(l, Tokens.EOF_MULTICOMMENT)
            end
            nc = readchar(l)
            if c == '#' && nc == '='
                n_start += 1
            elseif c == '=' && nc == '#'
                n_end += 1
            end
            if n_start == n_end
                break
            end
            c = nc
        end
    end
end


isempty(t::Token) = t.kind == Tokens.begin_delimiters