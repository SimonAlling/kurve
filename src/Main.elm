port module Main exposing (main)

import Browser
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Time


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


type alias DrawingPosition =
    ()


type alias State =
    { x : Float, y : Float }


type alias Model =
    { currentState : State
    , previousState : State
    , currentTime : Float
    , accumulator : Float
    , stateToRender : State
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initState =
            { x = 0, y = 100 }
    in
    ( { currentState = initState
      , previousState = initState
      , currentTime = 0
      , accumulator = 0
      , stateToRender = initState
      }
    , Cmd.none
    )


type Msg
    = GameTick Time.Posix


tickrate : number
tickrate =
    60


dt : Float
dt =
    0.01


speed : number
speed =
    -- px per second
    60


update : Msg -> Model -> ( Model, Cmd Msg )
update (GameTick timestamp) model =
    let
        -- double newTime = time();
        newTime =
            (toFloat <| Time.posixToMillis timestamp) / 1000

        -- double frameTime = newTime - currentTime;
        -- if ( frameTime > 0.25 )
        --     frameTime = 0.25;
        frameTime =
            min 0.25 (newTime - model.currentTime)

        -- currentTime = newTime;
        currentTime =
            newTime

        -- accumulator += frameTime;
        accumulatorBeforeLoop =
            model.accumulator + frameTime

        -- while ( accumulator >= dt )
        -- {
        --     previousState = currentState;
        --     integrate( currentState, t, dt );
        --     t += dt;                                       TODO
        --     accumulator -= dt;
        -- }
        { previousState, currentState, accumulator } =
            whileLoop
                { previousState = model.previousState
                , currentState = model.currentState
                , accumulator = accumulatorBeforeLoop
                }

        -- const double alpha = accumulator / dt;
        alpha =
            accumulator / dt

        -- State state = currentState * alpha +
        --     previousState * ( 1.0 - alpha );
        stateToRender =
            addStates (multiplyState alpha currentState) (multiplyState (1.0 - alpha) previousState)
    in
    ( { currentState = currentState
      , previousState = previousState
      , currentTime = currentTime
      , accumulator = accumulator
      , stateToRender = stateToRender
      }
    , renderState stateToRender
    )


type alias WhileLoopData =
    { previousState : State
    , currentState : State
    , accumulator : Float
    }


whileLoop : WhileLoopData -> WhileLoopData
whileLoop ({ currentState, accumulator } as loopData) =
    -- while ( accumulator >= dt )
    if accumulator >= dt then
        whileLoop
            { -- previousState = currentState;
              previousState = currentState

            -- integrate( currentState, t, dt );
            , currentState = computeNewState currentState dt

            -- accumulator -= dt;
            , accumulator = accumulator - dt
            }

    else
        loopData


multiplyState : Float -> State -> State
multiplyState alpha { x, y } =
    { x = x * alpha, y = alpha * y }


addStates : State -> State -> State
addStates a b =
    { x = a.x + b.x, y = a.y + b.y }


renderState : State -> Cmd msg
renderState state =
    render [ { position = (), thickness = 5, color = "white" } ]


computeNewState : State -> Float -> State
computeNewState { x, y } dt_ =
    { x = x + speed * dt_, y = y }


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every (1 / tickrate) GameTick


view : Model -> Html Msg
view model =
    elmRoot
        []
        [ canvas
            [ Attr.id "canvas_main"
            , Attr.width 1920
            , Attr.height 480
            , Attr.style "background" "black"
            ]
            []
        ]


elmRoot : List (Html.Attribute msg) -> List (Html msg) -> Html msg
elmRoot attrs =
    div (Attr.id "elm-root" :: attrs)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
