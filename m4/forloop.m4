m4_divert(`-1')
# forloop(var, from, to, stmt) - simple version
m4_define(`m4_forloop', `m4_pushdef(`$1', `$2')_forloop($@)m4_popdef(`$1')')
m4_define(`_forloop',
       `$4`'m4_ifelse($1, `$3', `', `m4_define(`$1', m4_incr($1))$0($@)')')
m4_divert`'m4_dnl
