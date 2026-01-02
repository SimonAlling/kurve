module TestHelpers.PlayerInput exposing
    ( press
    , pressAndRelease
    , release
    )

import Input exposing (Button, ButtonDirection(..))
import Main exposing (Msg(..))


pressAndRelease : Button -> List Msg
pressAndRelease button =
    press button ++ release button


press : Button -> List Msg
press =
    ButtonUsed Down >> List.singleton


release : Button -> List Msg
release =
    ButtonUsed Up >> List.singleton
