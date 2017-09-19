using CSTParser
using Base.Test

import CSTParser: parse, remlineinfo!, span, flisp_parse

ps = CSTParser.ParseState("fdsfds")
@code_llvm CSTParser.parse_kw(ps)

include("parser.jl")
# include("diagnostics.jl")

# CSTParser.check_base()
