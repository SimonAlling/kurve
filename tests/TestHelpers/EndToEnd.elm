module TestHelpers.EndToEnd exposing (endToEndTest)

import Effect exposing (Effect)
import Main exposing (Model, Msg, update)


endToEndTest : Model -> List Msg -> ( Model, List Effect )
endToEndTest initialModel messages =
    List.foldl consumeMsg ( initialModel, [] ) messages
        |> Tuple.mapSecond List.reverse


consumeMsg : Msg -> ( Model, List Effect ) -> ( Model, List Effect )
consumeMsg msg ( model, reversedEffectsSoFar ) =
    let
        ( newModel, effectForThisUpdate ) =
            update msg model
    in
    ( newModel, effectForThisUpdate :: reversedEffectsSoFar )
