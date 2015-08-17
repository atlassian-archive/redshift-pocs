m4_divert(`-1')
# m4_quote(args) - convert args to single-quoted string
m4_define(`m4_quote', `m4_ifelse(`$#', `0', `', ``$*'')')
# m4_dquote(args) - convert args to quoted list of quoted strings
m4_define(`m4_dquote', ``$@'')
# m4_dquote_elt(args) - convert args to list of double-quoted strings
m4_define(`m4_dquote_elt', `m4_ifelse(`$#', `0', `', `$#', `1', ```$1''',
                             ```$1'',$0(m4_shift($@))')')
m4_divert`'m4_dnl
