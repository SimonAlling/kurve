module ScenarioComments exposing (ignoreBogusWriteComment, setStateComponentComment)

import MemoryLayout exposing (StateComponent(..))
import OriginalGamePlayers exposing (PlayerId(..), playerName)


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


showStateComponent : StateComponent -> String
showStateComponent stateComponent =
    case stateComponent of
        X ->
            "x"

        Y ->
            "y"

        Dir ->
            "direction"
