using CSTParser
using Base.Test

import CSTParser: parse, remlineinfo!, span, flisp_parse

include("parser.jl")
# include("diagnostics.jl")
ps = CSTParser.ParseState("fdsfds")
@code_llvm CSTParser.parse_kw(ps)

# CSTParser.check_base()
