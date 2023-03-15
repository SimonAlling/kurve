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
        "AltLeft" ->
            Named "L.Alt"

        "AltRight" ->
            -- Could have been "AltGr", but this is nicely dual to "L.Alt"; they are in turn analogous to "L.Ctrl" (from the original game) and "R.Ctrl".
            Named "R.Alt"

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

        "AudioVolumeDown" ->
            Named "VolDn"

        "AudioVolumeMute" ->
            Named "Mute"

        "AudioVolumeUp" ->
            Named "VolUp"

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

        "CapsLock" ->
            Named "CapsLk"

        "Comma" ->
            -- From the original game.
            Character ','

        "ContextMenu" ->
            Named "Menu"

        "ControlLeft" ->
            Named "L.Ctrl"

        "ControlRight" ->
            Named "R.Ctrl"

        "Delete" ->
            Named "Del"

        "End" ->
            Named "End"

        "Enter" ->
            Named "Enter"

        "Equal" ->
            Character '='

        "Escape" ->
            Named "Esc"

        "Home" ->
            Named "Home"

        "Insert" ->
            Named "Ins"

        "IntlBackslash" ->
            -- Unclear what this key can be said to represent, but it produces a '\' in the English (UK) layout.
            Character '\\'

        "Minus" ->
            Character '-'

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

        "PageDown" ->
            Named "PgDn"

        "PageUp" ->
            Named "PgUp"

        "Pause" ->
            Named "Pause"

        "Period" ->
            Character '.'

        "PrintScreen" ->
            Named "PrtSc"

        "Quote" ->
            Character '\''

        "ScrollLock" ->
            Named "ScrLk"

        "Semicolon" ->
            Character ';'

        "ShiftLeft" ->
            Named "L.Shift"

        "ShiftRight" ->
            Named "R.Shift"

        "Slash" ->
            Character '/'

        "Space" ->
            Named "Space"

        "Tab" ->
            Named "Tab"

        "VolumeDown" ->
            Named "VolDn"

        "VolumeMute" ->
            Named "Mute"

        "VolumeUp" ->
            Named "VolUp"

        _ ->
            Unknown
