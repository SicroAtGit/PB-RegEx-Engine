
DeclareModule RegEx
  
  EnableExplicit
  
  Enumeration SpecialSymbols 0 Step -1
    #Symbol_Move  ; Used for NFA epsilon moves
    #Symbol_Split ; Used for NFA unions
    #Symbol_Final ; Used for NFA final state
  EndEnumeration
  
  Structure NfaStateStruc
    symbol.i    ; Unicode number or special symbol number
    *nextState1 ; Pointer to the first next NFA state
    *nextState2 ; Pointer to the second next NFA state
  EndStructure
  
  Structure DfaStateStruc
    Map symbols.i() ; Key is the symbol and the value is the next DFA state
    isFinalState.i  ; #True if the DFA state is a final state, otherwise #False
  EndStructure
  
  Structure RegExEngineStruc
    *regExString.Character               ; Pointer to the RegEx string
    List nfaStatesPool.NfaStateStruc()   ; Holds all NFA states
    *initialNfaState                     ; Pointer to the NFA initial state
    Array dfaStatesPool.DfaStateStruc(0) ; Holds all DFA states
  EndStructure
  
  ; Creates a new RegEx engine and returns the pointer to the
  ; `RegExEngineStruc` structure. If an error occurred (RegEx syntax error or
  ; memory could not be allocated) null is returned.
  Declare Create(regExString$)
  
  ; Creates a DFA in the RegEx engine from the NFA created by `Create()`.
  ; `Match()` then always uses the DFA and is much faster.
  ; Because the NFA is no longer used after this, it is freed by default.
  ; The freeing can be turned off by setting `freeNfa` to `#False`.
  Declare CreateDfa(*regExEngine.RegExEngineStruc, freeNfa = #True)
  
  ; Frees the memory of the RegEx engine created by the function `Create`.
  Declare Free(*regExEngine)
  
  ; Runs the Regex engine against the string. The function requires the pointer
  ; to the string, which can be determined with `@variable$` or `@"text"`.
  ; The match search will start from the beginning of the string. If you want
  ; to start from a different position, you have to move the pointer of the
  ; string, e.g. `*string + SizeOf(Character)` to search from the second
  ; character in the string. If a match is found, the character length of the
  ; match is returned, otherwise zero.
  Declare Match(*regExEngine, *string)
  
EndDeclareModule

Module RegEx
  
  Structure NfaStruc
    *startState.NfaStateStruc
    *endState.NfaStateStruc
  EndStructure
  
  Structure EClosureStruc
    List *nfaStates()
  EndStructure
  
  Declare ParseRegEx(*regExEngine.RegExEngineStruc)
  
  Procedure CreateNfaState(*regExEngine.RegExEngineStruc)
    ProcedureReturn AddElement(*regExEngine\nfaStatesPool())
  EndProcedure
  
  Procedure DeleteNfaState(*regExEngine.RegExEngineStruc, *state)
    ChangeCurrentElement(*regExEngine\nfaStatesPool(), *state)
    DeleteElement(*regExEngine\nfaStatesPool())
  EndProcedure
  
  Procedure CreateNfaSymbol(*regExEngine.RegExEngineStruc, symbol)
    Protected.NfaStruc *resultNfa = AllocateStructure(NfaStruc)
    
    *resultNfa\startState = CreateNfaState(*regExEngine)
    *resultNfa\startState\symbol = symbol
    
    *resultNfa\endState = CreateNfaState(*regExEngine)
    *resultNfa\endState\symbol = #Symbol_Final
    
    *resultNfa\startState\nextState1 = *resultNfa\endState
    
    ProcedureReturn *resultNfa
  EndProcedure
  
  Procedure CreateNfaConcatenation(*regExEngine.RegExEngineStruc, *nfa1.NfaStruc, *nfa2.NfaStruc)
    Protected.NfaStruc *resultNfa = AllocateStructure(NfaStruc)
    
    *nfa1\endState\symbol = *nfa2\startState\symbol
    *nfa1\endState\nextState1 = *nfa2\startState\nextState1
    *nfa1\endState\nextState2 = *nfa2\startState\nextState2
    
    DeleteNfaState(*regExEngine, *nfa2\startState)
    
    *resultNfa\startState = *nfa1\startState
    *resultNfa\endState = *nfa2\endState
    
    ProcedureReturn *resultNfa
  EndProcedure
  
  Procedure CreateNfaUnion(*regExEngine.RegExEngineStruc, *nfa1.NfaStruc, *nfa2.NfaStruc)
    Protected.NfaStruc *resultNfa = AllocateStructure(NfaStruc)
    
    *resultNfa\startState = CreateNfaState(*regExEngine)
    *resultNfa\startState\symbol = #Symbol_Split
    *resultNfa\startState\nextState1 = *nfa1\startState
    *resultNfa\startState\nextState2 = *nfa2\startState
    
    *resultNfa\endState = CreateNfaState(*regExEngine)
    *resultNfa\endState\symbol = #Symbol_Final
    
    *nfa1\endState\symbol = #Symbol_Move
    *nfa1\endState\nextState1 = *resultNfa\endState
    
    *nfa2\endState\symbol = #Symbol_Move
    *nfa2\endState\nextState1 = *resultNfa\endState
    
    ProcedureReturn *resultNfa
  EndProcedure
  
  Procedure CreateNfaZeroOrMore(*regExEngine.RegExEngineStruc, *nfa.NfaStruc)
    Protected.NfaStruc *resultNfa = AllocateStructure(NfaStruc)
    
    *resultNfa\startState = CreateNfaState(*regExEngine)
    *resultNfa\startState\symbol = #Symbol_Split
    
    *resultNfa\endState = CreateNfaState(*regExEngine)
    *resultNfa\endState\symbol = #Symbol_Final
    
    *resultNfa\startState\nextState1 = *nfa\startState
    *resultNfa\startState\nextState2 = *resultNfa\endState
    
    *nfa\endState\symbol = #Symbol_Split
    *nfa\endState\nextState1 = *resultNfa\endState
    *nfa\endState\nextState2 = *nfa\startState
    
    ProcedureReturn *resultNfa
  EndProcedure
  
  Procedure CreateNfaOneOrMore(*regExEngine.RegExEngineStruc, *nfa.NfaStruc)
    Protected.NfaStruc *resultNfa = AllocateStructure(NfaStruc)
    
    *resultNfa\startState = CreateNfaState(*regExEngine)
    *resultNfa\startState\symbol = #Symbol_Move
    
    *resultNfa\endState = CreateNfaState(*regExEngine)
    *resultNfa\endState\symbol = #Symbol_Final
    
    *resultNfa\startState\nextState1 = *nfa\startState
    
    *nfa\endState\symbol = #Symbol_Split
    *nfa\endState\nextState1 = *resultNfa\endState
    *nfa\endState\nextState2 = *nfa\startState
    
    ProcedureReturn *resultNfa
  EndProcedure
  
  Procedure CreateNfaZeroOrOne(*regExEngine.RegExEngineStruc, *nfa.NfaStruc)
    Protected *nfa2, *resultNfa
    
    *nfa2 = CreateNfaSymbol(*regExEngine, #Symbol_Move)
    *resultNfa = CreateNfaUnion(*regExEngine, *nfa, *nfa2)
    FreeStructure(*nfa2)
    
    ProcedureReturn *resultNfa
  EndProcedure
  
  Procedure ParseRegExBase(*regExEngine.RegExEngineStruc)
    Protected *base, *nfa1, *nfa2
    
    Select *regExEngine\regExString\c
      Case '('
        *regExEngine\regExString + SizeOf(Character)
        *base = ParseRegEx(*regExEngine)
        If *regExEngine\regExString\c <> ')'
          ProcedureReturn 0
        EndIf
        *regExEngine\regExString + SizeOf(Character)
      Case '\'
        *regExEngine\regExString + SizeOf(Character)
        Select *regExEngine\regExString\c
          Case '*', '+', '?', '|', '(', ')', '\'
            *base = CreateNfaSymbol(*regExEngine, *regExEngine\regExString\c)
            *regExEngine\regExString + SizeOf(Character)
          Default
            ProcedureReturn 0
        EndSelect
      Case '*', '+', '?', ')', '|', ''
        ProcedureReturn 0
      Default
        *base = CreateNfaSymbol(*regExEngine, *regExEngine\regExString\c)
        *regExEngine\regExString + SizeOf(Character)
    EndSelect
    
    ProcedureReturn *base
  EndProcedure
  
  Procedure ParseRegExFactor(*regExEngine.RegExEngineStruc)
    Protected *base = ParseRegExBase(*regExEngine)
    Protected *factor
    
    If *base = 0
      ProcedureReturn 0
    EndIf
    
    Select *regExEngine\regExString\c
      Case '*'
        *regExEngine\regExString + SizeOf(Character)
        *factor = CreateNfaZeroOrMore(*regExEngine, *base)
        FreeStructure(*base)
      Case '+'
        *regExEngine\regExString + SizeOf(Character)
        *factor = CreateNfaOneOrMore(*regExEngine, *base)
        FreeStructure(*base)
      Case '?'
        *regExEngine\regExString + SizeOf(Character)
        *factor = CreateNfaZeroOrOne(*regExEngine, *base)
        FreeStructure(*base)
      Default
        *factor = *base
    EndSelect
    
    ProcedureReturn *factor
  EndProcedure
  
  Procedure ParseRegExTerm(*regExEngine.RegExEngineStruc)
    Protected *factor, *newFactor, *nextFactor
    
    *factor = ParseRegExFactor(*regExEngine)
    
    If *factor = 0
      ProcedureReturn 0
    EndIf
    
    While *regExEngine\regExString\c <> 0 And *regExEngine\regExString\c <> ')' And
          *regExEngine\regExString\c <> '|'
      
      *nextFactor = ParseRegExFactor(*regExEngine)
      
      If *nextFactor = 0
        ProcedureReturn 0
      EndIf
      
      *newFactor = CreateNfaConcatenation(*regExEngine, *factor, *nextFactor)
      FreeStructure(*factor)
      FreeStructure(*nextFactor)
      *factor = *newFactor
    Wend
    
    ProcedureReturn *factor
  EndProcedure
  
  Procedure ParseRegEx(*regExEngine.RegExEngineStruc)
    Protected *term = ParseRegExTerm(*regExEngine)
    Protected *regEx, *union
    
    If *term And *regExEngine\regExString\c = '|'
      *regExEngine\regExString + SizeOf(Character)
      *regEx = ParseRegEx(*regExEngine)
      If *regEx
        *union = CreateNfaUnion(*regExEngine, *term, *regEx)
      Else
        *union = 0
      EndIf
      FreeStructure(*term)
      FreeStructure(*regEx)
      ProcedureReturn *union
    Else
      ProcedureReturn *term
    EndIf
  EndProcedure
  
  Procedure Create(regExString$)
    Protected.RegExEngineStruc *regExEngine
    Protected.NfaStruc *resultNfa
    
    If regExString$ = ""
      ProcedureReturn 0
    EndIf
    
    *regExEngine = AllocateStructure(RegExEngineStruc)
    If *regExEngine
      *regExEngine\regExString = @regExString$
      *resultNfa = ParseRegEx(*regExEngine)
      If *resultNfa
        *regExEngine\initialNfaState = *resultNfa\startState
      Else
        FreeStructure(*regExEngine)
        *regExEngine = 0
      EndIf
    EndIf
    
    If *regExEngine And *regExEngine\regExString\c <> 0
      ; If the regex string could not be parsed completely, there are syntax
      ; errors
      *regExEngine = 0
    EndIf
    
    ProcedureReturn *regExEngine
  EndProcedure
  
  Procedure AddState(*state.NfaStateStruc, List *states())
    If *state\symbol = #Symbol_Split
      AddState(*state\nextState1, *states())
      AddState(*state\nextState2, *states())
    ElseIf *state\symbol = #Symbol_Move
      AddState(*state\nextState1, *states())
    Else
      AddElement(*states())
      *states() = *state
    EndIf
  EndProcedure
  
  Procedure FindStatesSet(Array eClosures.EClosureStruc(1), List *states())
    Protected sizeOfArray, dfaState, countOfStates, isFound, result
    
    sizeOfArray = ArraySize(eClosures())
    countOfStates = ListSize(*states())
    
    For dfaState = 0 To sizeOfArray
      
      isFound = #True
      
      If ListSize(eClosures(dfaState)\nfaStates()) <> countOfStates
        Continue
      EndIf
      
      ResetList(*states())
      ResetList(eClosures(dfaState)\nfaStates())
      
      While NextElement(*states()) And NextElement(eClosures(dfaState)\nfaStates())
        If eClosures(dfaState)\nfaStates() <> *states()
          isFound = #False
          Break
        EndIf
      Wend
      
      If isFound
        result = dfaState
        Break
      EndIf
    Next
    
    ProcedureReturn result
  EndProcedure
  
  Procedure CreateDfa(*regExEngine.RegExEngineStruc, freeNfa = #True)
    Protected.EClosureStruc Dim eClosures(0), NewMap symbols()
    Protected.NfaStateStruc *state
    Protected sizeOfArray, dfaState, result
    
    AddState(*regExEngine\initialNfaState, eClosures(dfaState)\nfaStates())
    
    For dfaState = 0 To ArraySize(eClosures())
      
      ClearMap(symbols())
      
      ForEach eClosures(dfaState)\nfaStates()
        *state = eClosures(dfaState)\nfaStates()
        Select *state\symbol
          Case #Symbol_Final
            *regExEngine\dfaStatesPool(dfaState)\isFinalState = #True
          Default
            AddState(*state\nextState1, symbols(Chr(*state\symbol))\nfaStates())
        EndSelect
      Next
      
      ForEach symbols()
        result = FindStatesSet(eClosures(), symbols()\nfaStates())
        If result
          *regExEngine\dfaStatesPool(dfaState)\symbols(MapKey(symbols())) = result
        Else
          sizeOfArray = ArraySize(eClosures())
          ReDim eClosures(sizeOfArray + 1)
          ReDim *regExEngine\dfaStatesPool(sizeOfArray + 1)
          CopyList(symbols()\nfaStates(), eClosures(sizeOfArray + 1)\nfaStates())
          *regExEngine\dfaStatesPool(dfaState)\symbols(MapKey(symbols())) = sizeOfArray + 1
        EndIf
      Next
      
    Next
    
    If freeNfa
      *regExEngine\initialNfaState = 0
      FreeList(*regExEngine\nfaStatesPool())
    EndIf
  EndProcedure
  
  Procedure Free(*regExEngine.RegExEngineStruc)
    FreeStructure(*regExEngine)
  EndProcedure
  
  Procedure NfaMatch(*regExEngine.RegExEngineStruc, *string.Character)
    Protected.NfaStateStruc *state
    Protected matchLength, lastFinalStateMatchLength
    Protected NewList *currentStates(), NewList *nextStates()
    
    AddState(*regExEngine\initialNfaState, *currentStates())
    
    Repeat
      ForEach *currentStates()
        *state = *currentStates()
        If *state\symbol = *string\c
          AddState(*state\nextState1, *nextStates())
        ElseIf *state\symbol = #Symbol_Final
          lastFinalStateMatchLength = matchLength
        EndIf
      Next
      
      If ListSize(*nextStates()) = 0
        Break
      EndIf
      
      ClearList(*currentStates())
      MergeLists(*nextStates(), *currentStates())
      
      *string + SizeOf(Character)
      matchLength + 1
    ForEver
    
    ProcedureReturn lastFinalStateMatchLength
  EndProcedure
  
  Procedure DfaMatch(*regExEngine.RegExEngineStruc, *string.Character)
    Protected dfaState, matchLength, lastFinalStateMatchLength
    
    While *string\c
      
      If Not FindMapElement(*regExEngine\dfaStatesPool(dfaState)\symbols(), Chr(*string\c))
        Break
      EndIf
      dfaState = *regExEngine\dfaStatesPool(dfaState)\symbols()
      
      matchLength + 1
      *string + SizeOf(Character)
      
      If *regExEngine\dfaStatesPool(dfaState)\isFinalState
        lastFinalStateMatchLength = matchLength
      EndIf
    Wend
    
    ProcedureReturn lastFinalStateMatchLength
  EndProcedure
  
  Procedure Match(*regExEngine.RegExEngineStruc, *string.Character)
    If MapSize(*regExEngine\dfaStatesPool(0)\symbols())
      ProcedureReturn DfaMatch(*regExEngine, *string)
    Else
      ProcedureReturn NfaMatch(*regExEngine, *string)
    EndIf
  EndProcedure
  
EndModule
