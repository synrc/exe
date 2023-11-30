-module(sh_path).
-export([escape/1, unescape/1]).

escape(Path) -> R = reserved(), lists:append([char_encode(Char, R) || Char <- Path]).
unescape(Str) -> uri_string:unquote(Str).
reserved() -> sets:from_list([$/, $\\, $:, $%]).
char_encode(Char, Reserved) ->
    case sets:is_element(Char, Reserved) of
        true -> [$% | http_util:integer_to_hexlist(Char)];
        false -> [Char] end.
