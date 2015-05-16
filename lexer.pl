reserved(Word) :-
	member(Word, [and,begin,case,continue,def,default,do,end,elif,else,if,not,or,pass,switch,while,var]).

id_initial_char(Char) :-
	atom_codes(C, [Char]),
	(C = '_' ; unicode_property(C, category('L'))).

id_char(Char) :-
	atom_codes(C, [Char]),
	(C = '_' ; unicode_property(C, category('L')) ; unicode_property(C, category('N'))).

delim_char(Delim) :-
	member(Delim, ` \t\r\n!%^&*-+=|<>/~()[]{}:;,\\`).

% base case: end of input
lex([], []).
% space - just skip over, don't create token
lex([Space|String], Tokens) :-
	[Space] = ` `,
	lex(String, Tokens).
% standalone single-char punctuation symbols and whitespace
lex([Punct|String], [Symbol|Tokens]) :-
	member(Punct, `~()[]{}:;,\\\t\r\n`),
	atom_string(Symbol, [Punct]),
	lex(String, Tokens).
% op-equals (+=, -=, >=, ==, !=, etc)
lex([Op,Eq|String], [Opeq|Tokens]) :-
	member(Op, `!%^&*-+=|<>/`),
	[Eq] = `=`,
	atom_string(Opeq, [Op, Eq]),
	lex(String, Tokens).
% standalone op for op that could be part of op-equals
lex([Punct,Char|String], [Symbol|Tokens]) :-
	member(Punct, `!%^&*-+=|<>/`),
	[Char] \= `=`,
	atom_string(Symbol, [Punct]),
	lex([Char|String], Tokens).
% start of string literal
lex([Quote|Input], [string(String)|Tokens]) :-
	[Quote] = `\"`,
	literal_string(Input, String, RemainingInput),
	lex(RemainingInput, Tokens).
% start of numeric literal
lex([Digit|Input], [NumValue|Tokens]) :-
	member(Digit, `0123456789`),
	literal_number([Digit|Input], NumValue, RemainingInput),
	lex(RemainingInput, Tokens).
% start of character literal
lex([Quote|Input], [char(Char)|Tokens]) :-
	[Quote] = `\'`,
	literal_char(Input, Char, RemainingInput),
	lex(RemainingInput, Tokens).
% identifiers and keywords
lex([Char|Input], [Tok|Tokens]) :-
	id_initial_char(Char),
	lex_word([Char|Input], WordCodes, RemainingInput),
	atom_codes(Word, WordCodes),
	(reserved(Word)
		-> Tok = Word
		;  Tok = id(Word)),
	lex(RemainingInput, Tokens).

% base case: end of input
lex_word([], [], []).
% base case: end of word
lex_word([Delim|Input], [], [Delim|Input]) :-
	delim_char(Delim).
% word char
lex_word([Char|Input], [Char|Word], RemainingInput) :-
	id_char(Char),
	lex_word(Input, Word, RemainingInput).

% base case: end quote
literal_string([Quote|Input], [], Input) :-
	[Quote] = `\"`.
% backslash - start of escape sequence
literal_string([Esc|Input], [EscChar|StringValue], RemainingInput) :-
	[Esc] = `\\`,
	escape_code(Input, EscChar, MidInput),
	literal_string(MidInput, StringValue, RemainingInput).
% non-escape character in the string
literal_string([Char|Input], [Char|StringValue], RemainingInput) :-
	\+ member(Char, `\\\"`),
	literal_string(Input, StringValue, RemainingInput).

% backslash - start of escape sequence
literal_char([Esc|Input], EscChar, RemainingInput) :-
	[Esc,Quote] = `\\\'`,
	escape_code(Input, EscChar, [Quote|RemainingInput]).
% non-escape character
literal_char([Char,Quote|Input], Char, Input) :-
	\+ member(Char, `\\\'`),
	[Quote] = `\'`.

escape_code([Char|String], CharValue, String) :-
	nth0(Idx, `abfnrtv01234567\\'\"`, Char),
	nth0(Idx, `\a\b\f\n\r\t\v\0\1\2\3\4\5\6\7\\\'\"`, CharValue).
escape_code([X,D1,D2|String], CharValue, String) :-
	[X] = `x`,
	nth0(N1, `0123456789abcdefABCDEF`, D1),
	nth0(N2, `0123456789abcdefABCDEF`, D2),
	nth0(N1, [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,10,11,12,13,14,15], V1),
	nth0(N2, [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,10,11,12,13,14,15], V2),
	CharValue is V1 * 16 + V2.

% hexadecimal literals
literal_number([O,X|Input], int(Value), RemainingInput) :-
	[O,X] = `0x`,
	literal_hex(Input, 0, Value, RemainingInput).
% decimal integer literals
/*literal_number(Input, int(Value), [Char|RemainingInput]) :-
	literal_int(Input, Value, [Char|RemainingInput]),
	\+ member(Char, `.efL`).
% decimal float literals
literal_number(Input, float(Value), RemainingInput) :-
	literal_int(Input, PrePt, [Pt|MidInput]),
	[Pt] = `.`,
	literal_int(MidInput, PostPt, RemainingInput),
	Value is [PrePt,PostPt]. %TODO: fix
% scientific float literals
% TODO
*/

% base case: end of input
literal_hex([], Value, Value, []).
% base case: end of literal
literal_hex([Delim|Input], Value, Value, [Delim|Input]) :-
	delim_char(Delim).
literal_hex([Digit|Input], Prev, Value, RemainingInput) :-
	nth0(N, `0123456789abcdefABCDEF`, Digit),
	nth0(N, [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,10,11,12,13,14,15], V),
	Cur is Prev * 16 + V,
	literal_hex(Input, Cur, Value, RemainingInput).
