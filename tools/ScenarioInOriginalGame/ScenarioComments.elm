module ScenarioComments exposing (commentIgnoreBogusWrite, commentSetStateComponent)

import MemoryLayout exposing (StateComponent(..))
import OriginalGamePlayers exposing (PlayerId(..), playerName)


commentSetStateComponent : StateComponent -> PlayerId -> String
commentSetStateComponent stateComponent playerId =
    String.fromChar (playerIcon playerId) ++ " Set " ++ playerName playerId ++ "'s " ++ showStateComponent stateComponent


commentIgnoreBogusWrite : StateComponent -> PlayerId -> String
commentIgnoreBogusWrite stateComponent playerId =
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
