m4_include(`quote.m4')m4_dnl
m4_divert(`-1')
# foreachq(x, `item_1, item_2, ..., item_n', stmt)
#   quoted list, simple version
m4_define(`m4_foreachq', `m4_pushdef(`$1')_foreachq($@)m4_popdef(`$1')')
m4_define(`_arg1', `$1')
m4_define(`_foreachq', `m4_ifelse(m4_quote($2), `', `',
  `m4_define(`$1', `_arg1($2)')$3`'$0(`$1', `m4_shift($2)', `$3')')')
m4_divert`'m4_dnl
