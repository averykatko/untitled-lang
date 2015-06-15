if_statement --> [if], expression(bool), [':'], block(if, _Name), elif_list, else_statement.
elif_list --> [] ; (elif_statement, elif_list).
elif_statement --> [elif], expression(bool), [':'], block(elif, _Name).
else_statement --> [else, ':'], block(else, _Name).

switch_statement --> [switch], expression(Type), [':'], switch_block(Type, _Name).
switch_block(Type, Name) --> begin_statement(Name), ['{'], case_list(Type), ['}'], end_statement(Kind, Name).
case_list(_Type) --> default_statement, ([] ; statement_delim).
case_list(Type) --> case_statement(Type), statement_delim, case_list(Type).
case_statement(Type) --> [case], expression(Type), [':'], block(case, _Name).
default_statement --> [default, ':'], block(default, _Name).

while_loop --> [while], expression(bool), [':'], block(while, _Name).
do_loop --> [do, while], expression(bool), [':'], block(do, _Name).
for_loop --> [for, id(_I), of], expression(iterable),  [':'], block(for, _Name).

block(Kind, Name) --> begin_statement(Name), ['{'], statement_list(Kind), ['}'], end_statement(Kind, Name).
begin_statement([]) --> [].
begin_statement(Name) --> [begin, id(Name), ':'].
end_statement(Kind, Name) --> [] ; [end, Kind] ; [end, id(Name)].
statement_list(Kind) --> statement(Kind), ([] ; statement_delim).
statement_list(Kind) --> statement(Kind), statement_delim, statement_list(Kind).

statement(_Kind) --> if_statement ; switch_statement ; while_loop ; do_loop ; for_loop.
statement(case) --> continue_statement.
statement(Loop) --> {member(Loop, [while, do, for])}, (cycle_statement ; exit_statement).
statement --> declaration ; assignment(_Type) ; function_call(_Type) ; pass_statement.
statement --> return_statement(Type).

continue_statement --> [continue].
cycle_statement --> [cycle], ([] ; [id(Name)]).
exit_statement --> [exit], ([] ; [id(Name)]).
return_statement(void) --> [return].
return_statement(Type) --> [return], expression(Type).
pass_statement --> [pass].

declaration --> [def, id(Name), '='], expression(Type).
declaration --> [var, id(Name), '='], expression(Type).
declaration --> [var, id(Name), ':'], type_expression(Type).

assignment(Type) --> l_value(Type), ['='], expression(Type).

l_value(Type) --> [id(Name)].

type_expression(Type) --> [Type], {member(Type, [bool, int, float, string])}.

expression(Type) --> l_value(Type) ; assignment(Type) ; function_call(Type).
expression(bool) --> [true] ; [false].
expression(int) --> int(_Val).
expression(float) --> float(_Val).

function_call(Type) --> expression(ftype(ArgTypes,Type)), ['('], argument_list(ArgTypes), [')'].
argument_list([]) --> [].
argument_list([ArgType]) --> expression(ArgType).
argument_list([ArgType|ArgTypes]) --> expression(ArgType), [','], argument_list(ArgTypes).
