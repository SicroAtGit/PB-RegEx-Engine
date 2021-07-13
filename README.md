# Regular Expression Engine

> Development stage: Alpha version

## About

This RegEx engine compiles a regular expression into an E-NFA, optionally then into a very fast DFA, and can execute the E-NFA/DFA against a string.

The E-NFA is built with the [Thompson's construction](https://en.wikipedia.org/wiki/Thompson%27s_construction) and with two extra constructions for `x+` and `x?`.

When matching, the RegEx engine matches always the longest match among several possible matches (POSIX-compliant). During this process, no backtracking is required, because all alternations are checked simultaneously.

## Supported Syntax

| Syntax  | Meaning |
| ------- | ------- |
| `xy`    | `x` followed by `y` (Concatenation) |
| `x\|y`  | `x` or `y` (Alternation) |
| `x*`    | Zero or more of `x` |
| `x+`    | One or more of `x` |
| `x?`    | Zero or one of `x` |
| `(` `)` | Groups a regular expression |
| `\*`    | Escapes the meta-symbol `*` to use it as a normal character.<br>Works also with the other meta-symbols: `\|` `+` `?` `(` `)` `\` |

## Example

```purebasic
*regEx = RegEx::Create("test|example")
If *regEx
  If RegEx::Match(*regEx, @"example")
    Debug "Match!"
  Else
    Debug "No match!"
  EndIf
  RegEx::Free(*regEx)
Else
  Debug "Error!"
EndIf
```
More example codes can be found in the [`Example_codes`](Example_codes) directory.

## Public Enumerations

```purebasic
Enumeration SpecialSymbols 0 Step -1
  #Symbol_Move  ; Used for NFA epsilon moves
  #Symbol_Split ; Used for NFA unions
  #Symbol_Final ; Used for NFA final state
EndEnumeration
```

## Public Structures

```purebasic
Structure NfaStateStruc
  symbol.i    ; Unicode number or special symbol number
  *nextState1 ; Pointer to the first next NFA state
  *nextState2 ; Pointer to the second next NFA state
EndStructure
```

```purebasic
Structure DfaStateStruc
  Map symbols.i() ; Key is the symbol and the value is the next DFA state
  isFinalState.i  ; #True if the DFA state is a final state, otherwise #False
EndStructure
```

```purebasic
Structure RegExEngineStruc
  *regExString.Character               ; Pointer to the RegEx string
  List nfaStatesPool.NfaStateStruc()   ; Holds all NFA states
  *initialNfaState                     ; Pointer to the NFA initial state
  Array dfaStatesPool.DfaStateStruc(0) ; Holds all DFA states
EndStructure
```

## Public Functions

- `Create(regExString$)`  
Creates a new RegEx engine and returns the pointer to the `RegExEngineStruc` structure. If an error occurred (RegEx syntax error or memory could not be allocated) null is returned.

- `CreateDfa(*regExEngine, freeNfa = #True)`
Creates a DFA in the RegEx engine from the NFA created by `Create()`. `Match()` then always uses the DFA and is much faster. Because the NFA is no longer used after this, it is freed by default. The freeing can be turned off by setting `freeNfa` to `#False`.

- `Free(*regExEngine)`  
Frees the memory of the RegEx engine created by the function `Create()`.

- `Match(*regExEngine, *string)`  
Runs the Regex engine against the string. The function requires the pointer to the string, which can be determined with `@variable$` or `@"text"`. The match search will start from the beginning of the string. If you want to start from a different position, you have to move the pointer of the string, e.g. `*string + SizeOf(Character)` to search from the second character in the string. If a match is found, the character length of the match is returned, otherwise zero.
