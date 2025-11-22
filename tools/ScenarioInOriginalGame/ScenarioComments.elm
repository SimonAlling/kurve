module ScenarioComments exposing (ignoreBogusWriteComment, sectionEnd, sectionStart, setStateComponentComment)

import MemoryLayout exposing (StateComponent(..))
import OriginalGamePlayers exposing (PlayerId(..), playerName)


sectionStart : String -> String
sectionStart description =
    String.fromChar sectionStartIcon ++ " " ++ description


sectionEnd : String -> String
sectionEnd description =
    String.fromChar sectionEndIcon ++ " " ++ description


setStateComponentComment : StateComponent -> PlayerId -> String
setStateComponentComment stateComponent playerId =
    String.fromChar (playerIcon playerId) ++ " Set " ++ playerName playerId ++ "'s " ++ showStateComponent stateComponent


ignoreBogusWriteComment : StateComponent -> PlayerId -> String
ignoreBogusWriteComment stateComponent playerId =
    String.fromChar workaroundIcon ++ " Ignore bogus write to " ++ playerName playerId ++ "'s " ++ showStateComponent stateComponent


playerIcon : PlayerId -> Char
playerIcon playerId =
    case playerId of
        Red ->
            '🟥'

        Yellow ->
            '🟨'

        Orange ->
            '🟧'

        Green ->
            '🟩'

        Pink ->
            '🟪'

        Blue ->
            '🟦'


workaroundIcon : Char
workaroundIcon =
    '🔧'


sectionStartIcon : Char
sectionStartIcon =
    '⏳'


sectionEndIcon : Char
sectionEndIcon =
    '✅'


showStateComponent : StateComponent -> String
showStateComponent stateComponent =
    case stateComponent of
        X ->
            "x"

        Y ->
            "y"

        Dir ->
            "direction"
