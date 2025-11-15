module TheScenario exposing (theScenario)

import OriginalGamePlayers exposing (PlayerId(..))
import ScenarioCore exposing (Scenario)


theScenario : Scenario
theScenario =
    [ ( Red
      , { x = 200
        , y = 50
        , direction = pi / 2
        }
      )
    , ( Yellow
      , { x = 200
        , y = 100
        , direction = pi / 2
        }
      )
    , ( Green
      , { x = 200
        , y = 150
        , direction = pi / 2
        }
      )
    ]
