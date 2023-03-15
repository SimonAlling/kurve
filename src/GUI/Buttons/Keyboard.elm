module GUI.Buttons.Keyboard exposing (keyCodeRepresentation)

{-| This module contains logic for representing a key code (the `code` property of a `KeyboardEvent`) in a human-readable way.

There are three major aspects that make this non-trivial:

  - The `code` property represents a physical key, without any keyboard layout settings taken into consideration. For example, we cannot distinguish between "[" on an English keyboard, "Å" on a Swedish keyboard, and "Ü" on a German keyboard – all of them appear as `BracketLeft` to us.
  - There are differences between operating systems and browsers. For example, `OSLeft`/`MetaLeft` (depending on browser) is typically referred to as "Win" on Windows, "Super" on Linux and "Cmd" on macOS.
  - We can only render ASCII characters using the current GUI text implementation.

👉 <https://www.w3.org/TR/uievents-code>
👉 <https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_code_values>

-}


keyCodeRepresentation : String -> String
keyCodeRepresentation keyCode =
    case interpret keyCode of
        Character c ->
            String.fromChar c

        NumpadChar c ->
            "Num " ++ String.fromChar c

        FKey n ->
            "F" ++ String.fromInt n

        Named name ->
            name

        Unknown ->
            keyCode


type Interpretation
    = Character Char
    | NumpadChar Char
    | FKey Int
    | Named String
    | Unknown


interpret : String -> Interpretation
interpret keyCode =
    case String.toList keyCode of
        'D' :: 'i' :: 'g' :: 'i' :: 't' :: c :: [] ->
            -- DigitX
            Character c

        'K' :: 'e' :: 'y' :: c :: [] ->
            -- KeyX
            Character c

        'N' :: 'u' :: 'm' :: 'p' :: 'a' :: 'd' :: c :: [] ->
            -- NumpadX, where X is presumably a digit
            NumpadChar c

        _ ->
            parseFKey keyCode |> Maybe.withDefault (misc keyCode)


parseFKey : String -> Maybe Interpretation
parseFKey keyCode =
    case String.uncons keyCode of
        Just ( 'F', n ) ->
            -- FX, where X is a presumably positive integer
            String.toInt n |> Maybe.map FKey

        _ ->
            Nothing


{-| Miscellaneous keys.

Note: No button description in the original game exceeds 7 characters in length, and 8 is the maximum that's guaranteed to fit to the left of "READY".

-}
misc : String -> Interpretation
misc keyCode =
    case keyCode of
        {- Alphanumeric Section
           https://www.w3.org/TR/uievents-code/#key-alphanumeric-section
        -}
        "Backquote" ->
            Character '`'

        "Backslash" ->
            Character '\\'

        "Backspace" ->
            Named "Bksp"

        "BracketLeft" ->
            Character '['

        "BracketRight" ->
            Character ']'

        "Comma" ->
            -- From the original game.
            Character ','

        "Equal" ->
            Character '='

        "IntlBackslash" ->
            -- Unclear what this key can be said to represent, but it produces a '\' in the English (UK) layout.
            Character '\\'

        "Minus" ->
            Character '-'

        "Period" ->
            Character '.'

        "Quote" ->
            Character '\''

        "Semicolon" ->
            Character ';'

        "Slash" ->
            Character '/'

        {- Functional Keys
           https://www.w3.org/TR/uievents-code/#key-alphanumeric-functional
        -}
        "AltLeft" ->
            Named "L.Alt"

        "AltRight" ->
            -- Could have been "AltGr", but this is nicely dual to "L.Alt"; they are in turn analogous to "L.Ctrl" (from the original game) and "R.Ctrl".
            Named "R.Alt"

        "CapsLock" ->
            Named "CapsLk"

        "ContextMenu" ->
            Named "Menu"

        "ControlLeft" ->
            Named "L.Ctrl"

        "ControlRight" ->
            Named "R.Ctrl"

        "Enter" ->
            Named "Enter"

        "ShiftLeft" ->
            Named "L.Shift"

        "ShiftRight" ->
            Named "R.Shift"

        "Space" ->
            Named "Space"

        "Tab" ->
            Named "Tab"

        {- Control Pad Section
           https://www.w3.org/TR/uievents-code/#key-controlpad-section
        -}
        "Delete" ->
            Named "Del"

        "End" ->
            Named "End"

        "Home" ->
            Named "Home"

        "Insert" ->
            Named "Ins"

        "PageDown" ->
            Named "PgDn"

        "PageUp" ->
            Named "PgUp"

        {- Arrow Pad Section
           https://www.w3.org/TR/uievents-code/#key-arrowpad-section
        -}
        "ArrowDown" ->
            -- From the original game.
            Named "D.Arrow"

        "ArrowLeft" ->
            -- From the original game.
            Named "L.Arrow"

        "ArrowRight" ->
            Named "R.Arrow"

        "ArrowUp" ->
            Named "U.Arrow"

        {- Numpad Section
           https://www.w3.org/TR/uievents-code/#key-numpad-section
        -}
        "NumLock" ->
            Named "NumLk"

        "NumpadAdd" ->
            -- Just the character without any prefix to maintain consistency between the mathematical operators; 'NumpadMultiply' is rendered as '*' in the original game.
            Character '+'

        "NumpadComma" ->
            NumpadChar ','

        "NumpadDecimal" ->
            NumpadChar '.'

        "NumpadDivide" ->
            -- Just the character without any prefix to maintain consistency between the mathematical operators; 'NumpadMultiply' is rendered as '*' in the original game.
            Character '/'

        "NumpadEnter" ->
            Named "Enter"

        "NumpadEqual" ->
            -- Just the character without any prefix to maintain consistency between the mathematical operators; 'NumpadMultiply' is rendered as '*' in the original game.
            Character '='

        "NumpadMultiply" ->
            -- From the original game.
            Character '*'

        "NumpadParenLeft" ->
            NumpadChar '('

        "NumpadParenRight" ->
            NumpadChar ')'

        "NumpadSubtract" ->
            -- Just the character without any prefix to maintain consistency between the mathematical operators; 'NumpadMultiply' is rendered as '*' in the original game.
            Character '-'

        {- Function Section
           https://www.w3.org/TR/uievents-code/#key-function-section
        -}
        "Escape" ->
            Named "Esc"

        "Pause" ->
            Named "Pause"

        "PrintScreen" ->
            Named "PrtSc"

        "ScrollLock" ->
            Named "ScrLk"

        {- Media Keys
           https://www.w3.org/TR/uievents-code/#key-media
        -}
        "AudioVolumeDown" ->
            Named "VolDn"

        "AudioVolumeMute" ->
            Named "Mute"

        "AudioVolumeUp" ->
            Named "VolUp"

        "VolumeDown" ->
            Named "VolDn"

        "VolumeMute" ->
            Named "Mute"

        "VolumeUp" ->
            Named "VolUp"

        _ ->
            Unknown
