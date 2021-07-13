
IncludePath ".."
IncludeFile "RegExEngine.pbi"

Define.RegEx::RegExEngineStruc *regEx
Define sizeOfArray, i

*regEx = RegEx::Create("ab*")
If *regEx = 0
  Debug "Error"
  End
EndIf

RegEx::CreateDfa(*regEx)

Debug "| State               | Symbol | Next state          |"
Debug "| =================== | ====== | =================== |"
sizeOfArray = ArraySize(*regEx\dfaStatesPool())
For i = 0 To sizeofArray
  If *regEx\dfaStatesPool(i)\isFinalState
    Debug "| " + LSet(Str(i) + " (final)", 19) + " | " + Space(6) + " | " +
          Space(19) + " |"
  Else
    Debug "| " + LSet(Str(i), 19) + " | " + Space(6) + " | " + Space(19) + " |"
  EndIf
  
  ForEach *regEx\dfaStatesPool(i)\symbols()
    Debug "| " + Space(19) +
        " | " + LSet("'" + MapKey(*regEx\dfaStatesPool(i)\symbols()) + "'", 6) +
        " | " + LSet(Str(*regEx\dfaStatesPool(i)\symbols()), 19) + " |"
  Next
  Debug "| ------------------- | ------ | ------------------- |"
Next

RegEx::Free(*regEx)
