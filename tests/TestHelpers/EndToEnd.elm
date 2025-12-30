module TestHelpers.EndToEnd exposing (consumeMessages)

import Effect exposing (Effect)
import Main exposing (Model, Msg, update)


consumeMessages : Model -> List Msg -> ( Model, List Effect )
consumeMessages initialModel messages =
    List.foldl consumeMsg ( initialModel, [] ) messages
        |> Tuple.mapSecond List.reverse


consumeMsg : Msg -> ( Model, List Effect ) -> ( Model, List Effect )
consumeMsg msg ( model, reversedEffectsSoFar ) =
    let
        ( newModel, effectForThisUpdate ) =
            update msg model
    in
    ( newModel, effectForThisUpdate :: reversedEffectsSoFar )
