
IncludePath ".."
IncludeFile "RegExEngine.pbi"

Define.Character *string
Define *regEx
Define result
Define string$

string$ = "123_123x12 1"

*regEx = RegEx::Create("1|123|12")
If *regEx = 0
  Debug "Error"
  End
EndIf

Debug "== Results with NFA =="
Debug ""

*string = @string$
While *string\c
  result = RegEx::Match(*regEx, *string)
  If result
    Debug PeekS(*string, result)
  EndIf
  *string + SizeOf(Character)
Wend

Debug ""
Debug "== Results with DFA =="
Debug ""
RegEx::CreateDfa(*regEx)

*string = @string$
While *string\c
  result = RegEx::Match(*regEx, *string)
  If result
    Debug PeekS(*string, result)
  EndIf
  *string + SizeOf(Character)
Wend

RegEx::Free(*regEx)
