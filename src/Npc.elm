module Npc exposing
    ( Npc
    , Voice
    , actualPositionWithoutCursor
    , idleTexturePosition
    , inside
    , isHomeless
    , moveCollisionThreshold
    , moveEndTime
    , offset
    , random
    , randomMovement
    , size
    , textureSize
    , updateNpcPath
    , walkingLeftTexturePosition
    , walkingRightTexturePosition
    , walkingUpTexturePosition
    )

import Angle
import BoundingBox2d
import Bounds exposing (Bounds)
import Color exposing (Color)
import Coord exposing (Coord)
import Direction2d
import Duration exposing (Duration, Seconds)
import Effect.Time
import Grid exposing (Grid)
import GridCell
import Id exposing (Id, NpcId, UserId)
import List.Nonempty exposing (Nonempty(..))
import Name exposing (Name)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Random
import Tile exposing (BuildingData, Tile(..))
import Units exposing (CellUnit, WorldUnit)
import Vector2d exposing (Vector2d)


type alias Npc =
    { name : Name
    , home : Coord WorldUnit
    , position : Point2d WorldUnit WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Point2d WorldUnit WorldUnit
    , createdAt : Effect.Time.Posix
    , visitedPositions : Nonempty (Point2d WorldUnit WorldUnit)
    , skinColor : Color
    , clothColor : Color
    , voice : Voice
    }


type Voice
    = OldMan
    | OldWoman
    | Man
    | Woman
    | DistinguishedMan
    | DistinguishedWoman
    | EdgyTeenBoy
    | CoolKid
    | Nonbinary


isHomeless : Grid a -> Npc -> Bool
isHomeless grid npc =
    case Grid.getTile npc.home grid of
        Just a ->
            Coord.notEquals a.position npc.home

        Nothing ->
            True


moveCollisionThreshold : Quantity Float WorldUnit
moveCollisionThreshold =
    Units.tileUnit 0.01


walkSpeed : Quantity Float (Rate WorldUnit Seconds)
walkSpeed =
    Quantity.per Duration.second (Units.tileUnit 1.5)


walkingUpTexturePosition : Int -> Coord Pixels
walkingUpTexturePosition frameNumber =
    Coord.xy 484 (modBy 8 frameNumber * 17)


idleTexturePosition : Coord Pixels
idleTexturePosition =
    Coord.xy 494 0


offset : Coord Pixels
offset =
    Coord.xy -5 -15


textureSize : Coord Pixels
textureSize =
    Coord.xy 10 17


size : Coord Pixels
size =
    Coord.xy 8 5


walkingRightTexturePosition : Int -> Coord Pixels
walkingRightTexturePosition frameNumber =
    Coord.xy 494 (modBy 6 frameNumber * 17 + 17)


walkingLeftTexturePosition : Int -> Coord Pixels
walkingLeftTexturePosition frameNumber =
    Coord.xy 474 (modBy 6 frameNumber * 17 + 17)


moveEndTime : Npc -> Effect.Time.Posix
moveEndTime animal =
    let
        travelTime : Duration
        travelTime =
            Point2d.distanceFrom animal.position animal.endPosition
                |> Quantity.at_ walkSpeed
    in
    Duration.addTo animal.startTime travelTime


actualPositionWithoutCursor : Effect.Time.Posix -> Npc -> Point2d WorldUnit WorldUnit
actualPositionWithoutCursor time npc =
    let
        currentDistance : Quantity Float WorldUnit
        currentDistance =
            Duration.from npc.startTime time
                |> Quantity.at walkSpeed

        distance : Quantity Float WorldUnit
        distance =
            Point2d.distanceFrom npc.position npc.endPosition
    in
    Quantity.ratio currentDistance distance
        |> clamp 0 1
        |> Point2d.interpolateFrom npc.position npc.endPosition


navPoints : Tile -> List (Coord Pixels)
navPoints tile =
    case tile of
        Sidewalk ->
            [ Coord.xy 10 9 ]

        DirtPathHorizontal ->
            [ Coord.xy 12 9, Coord.xy 27 9 ]

        DirtPathVertical ->
            [ Coord.xy 10 10, Coord.xy 10 26 ]

        _ ->
            []


maxNavPointDistance : Quantity Float WorldUnit
maxNavPointDistance =
    Units.tileUnit 1.5


maxNavPointVector : Vector2d WorldUnit coordinates
maxNavPointVector =
    Vector2d.xy maxNavPointDistance maxNavPointDistance


getNavPoints : Id NpcId -> Npc -> Grid a -> Maybe (Point2d WorldUnit WorldUnit)
getNavPoints npcId npc grid =
    let
        minPoint : Point2d WorldUnit WorldUnit
        minPoint =
            Point2d.translateBy (Vector2d.reverse maxNavPointVector) npc.endPosition

        maxPoint : Point2d WorldUnit WorldUnit
        maxPoint =
            Point2d.translateBy maxNavPointVector npc.endPosition

        cellBounds : Bounds CellUnit
        cellBounds =
            Bounds.fromCoords
                (Nonempty
                    (maxPoint |> Grid.worldToCellPoint |> Coord.floorPoint)
                    [ minPoint |> Grid.worldToCellPoint |> Coord.floorPoint ]
                )
    in
    Bounds.coordRangeFold
        (\cellCoord state2 ->
            case Grid.getCell cellCoord grid of
                Just cell ->
                    List.foldl
                        (\{ tile, position } state3 ->
                            List.foldl
                                (\tileCoord state ->
                                    let
                                        navPoint : Point2d WorldUnit WorldUnit
                                        navPoint =
                                            Units.pixelToTilePoint tileCoord
                                                |> Point2d.translateBy
                                                    (Grid.cellAndLocalCoordToWorld ( cellCoord, position )
                                                        |> Coord.toVector2d
                                                    )

                                        (Quantity distance) =
                                            Point2d.distanceFrom navPoint npc.endPosition
                                    in
                                    if distance - Quantity.unwrap maxNavPointDistance < 0 && distance > 0.01 then
                                        let
                                            weight : Float
                                            weight =
                                                navPointWeighting npcId npc navPoint
                                        in
                                        if weight - state.minValue < 0 then
                                            case
                                                Grid.rayIntersection2 True
                                                    (Units.pixelToTileVector size
                                                        |> Vector2d.scaleBy 0.5
                                                    )
                                                    npc.endPosition
                                                    navPoint
                                                    grid
                                            of
                                                Just _ ->
                                                    state

                                                Nothing ->
                                                    { maybeMin = Just navPoint, minValue = weight }

                                        else
                                            state

                                    else
                                        state
                                )
                                state3
                                (navPoints tile)
                        )
                        state2
                        (GridCell.flatten cell)

                Nothing ->
                    state2
        )
        identity
        cellBounds
        { maybeMin = Nothing, minValue = 99999 }
        |> .maybeMin


updateNpcPath : Effect.Time.Posix -> Grid a -> Id NpcId -> Npc -> Npc
updateNpcPath time grid npcId npc =
    if Duration.from time (moveEndTime npc) |> Quantity.lessThanZero then
        updateNpcPathHelper 20 time grid npcId npc

    else
        npc


updateNpcPathHelper : Int -> Effect.Time.Posix -> Grid a -> Id NpcId -> Npc -> Npc
updateNpcPathHelper stepsLeft time grid npcId npc =
    if Duration.from time (moveEndTime npc) |> Quantity.lessThanZero then
        case getNavPoints npcId npc grid of
            Just head ->
                updateNpcPathHelper
                    (stepsLeft - 1)
                    time
                    grid
                    npcId
                    { position = npc.endPosition
                    , endPosition = head
                    , startTime =
                        if stepsLeft > 0 then
                            moveEndTime npc

                        else
                            time
                    , visitedPositions = List.Nonempty.take 3 npc.visitedPositions |> List.Nonempty.cons npc.endPosition
                    , name = npc.name
                    , home = npc.home
                    , createdAt = npc.createdAt
                    , skinColor = npc.skinColor
                    , clothColor = npc.clothColor
                    , voice = npc.voice
                    }

            Nothing ->
                npc

    else
        npc


navPointWeighting : Id NpcId -> Npc -> Point2d WorldUnit WorldUnit -> Float
navPointWeighting npcId npc navPoint =
    let
        scaleFactor : Float
        scaleFactor =
            Random.step (Random.float 0.9 1.1) (Random.initialSeed (Id.toInt npcId)) |> Tuple.first
    in
    List.Nonempty.foldl
        (\visited total ->
            total + 2 / max (Quantity.unwrap (Point2d.distanceFrom navPoint visited)) 0.1
        )
        0
        npc.visitedPositions
        |> (*) scaleFactor


randomMovement :
    Point2d WorldUnit WorldUnit
    -> Random.Generator (Maybe { endPosition : Point2d WorldUnit WorldUnit, delay : Duration })
randomMovement position =
    Random.map4
        (\shouldMove direction distance delay ->
            if shouldMove == 0 then
                { endPosition =
                    Point2d.translateIn
                        (Direction2d.fromAngle (Angle.degrees direction))
                        (Units.tileUnit distance)
                        position
                , delay = Duration.seconds delay
                }
                    |> Just

            else
                Nothing
        )
        (Random.int 0 2)
        (Random.float 0 360)
        (Random.float 2 10)
        (Random.float 1 1.5)


inside : Point2d WorldUnit WorldUnit -> Npc -> Bool
inside point npc =
    BoundingBox2d.from
        (Point2d.translateBy (Units.pixelToTileVector offset) npc.position)
        (Point2d.translateBy (Units.pixelToTileVector (Coord.plus textureSize offset)) npc.position)
        |> BoundingBox2d.contains point


random :
    Nonempty { position : Coord WorldUnit, userId : Id UserId, buildingData : BuildingData }
    -> Effect.Time.Posix
    -> Random.Generator Npc
random houses createdAt =
    Random.map4
        (\house ( name, voice ) skinColor clothColor ->
            let
                position =
                    Units.pixelToTilePoint house.buildingData.entrancePoint
                        |> Point2d.translateBy (Coord.toVector2d house.position)
            in
            { name = name
            , home = house.position
            , position = position
            , startTime = createdAt
            , endPosition = position
            , createdAt = createdAt
            , visitedPositions = Nonempty position []
            , skinColor = skinColor
            , clothColor = clothColor
            , voice = voice
            }
        )
        (List.Nonempty.sample houses)
        (List.Nonempty.sample namesAndVoice)
        randomSkinColor
        randomClothColor


namesAndVoice : Nonempty ( Name, Voice )
namesAndVoice =
    [ ( "Sven Svensson", OldMan )
    , ( "Alice Alicesson", OldWoman )
    , ( "James Jamesson", DistinguishedMan )
    , ( "Zane Umbra", EdgyTeenBoy )
    , ( "Mr. Smiggles", DistinguishedMan )
    , ( "Sir Bob", DistinguishedMan )
    , ( "Dorey Doe", OldWoman )
    , ( "Bumbu Balado", Man )
    , ( "Gebey Björn", Woman )
    , ( "Maheeeeen", Man )
    , ( "Joey Pizza", CoolKid )
    , ( "Jobbaly Joe", Man )
    , ( "Miss Lady", DistinguishedWoman )
    , ( "Doris Digitell", Woman )
    , ( "Efterston Grembridge", DistinguishedMan )
    , ( "Jeffree Wheeltoe", Man )
    , ( "Avie Aaronston", Woman )
    , ( "Dibble", Man )
    , ( "Brontsen Broodly", Man )
    , ( "Mrs. Lemonene", Woman )
    , ( "Otorow Elesly", Man )
    , ( "Emma Intsin", Woman )
    , ( "Os", Man )
    , ( "Louis Fenrir", Man )
    , ( "Marion Tallow", Woman )
    , ( "Lucienne", Woman )
    , ( "Lark Castille", Woman )
    , ( "Mina Ward", Woman )
    , ( "Lynn Vinet", Woman )
    , ( "Rove Simurgh", Nonbinary )
    , ( "Terin Selive", Woman )
    , ( "Aria Volk", Woman )
    , ( "Elyria Ingris", Woman )
    , ( "Ivory Valora", Woman )
    , ( "Jane Panteras", Woman )
    , ( "Alistair Middgrave", Man )
    , ( "Johanna Seraphine", Woman )
    , ( "Linus Seraphine", Man )
    , ( "Rosinia Sturm", Woman )
    , ( "Calast Drang", Man )
    , ( "Vokva Pressa", Woman )
    , ( "Foster", Nonbinary )
    , ( "Sheire Tusser", Woman )
    , ( "Robin Tusser", Woman )
    , ( "Asteria Regal", Woman )
    , ( "Adra", Woman )
    , ( "Alexis Gardilaw", Woman )
    , ( "Cecilia Gardilaw", Woman )
    , ( "Mal Greyskies", Nonbinary )
    , ( "Trisha Hailborn", Woman )
    , ( "Tanis Silverhand", Woman )
    , ( "Blitz Duster", Man )
    , ( "Kender Vieve", Man )
    , ( "Lil’ Eddy", CoolKid )
    , ( "Mahhra Freyn", Woman )
    , ( "Wolsh", Man )
    , ( "Omen Diamondbody", Man )
    , ( "Luxara Numens", Nonbinary )
    , ( "Samara Iocus", Woman )
    , ( "Aveline Winter", Woman )
    , ( "Newyn", Man )
    , ( "Maela Valtyra", Woman )
    , ( "The Mask", Man )
    , ( "Yannick", Man )
    , ( "Alexandre Dupont", Woman )
    , ( "Kytala Morfos", Woman )
    , ( "Aske", Man )
    , ( "Scarlex Soots", Woman )
    , ( "Vister", Nonbinary )
    , ( "Roz Xorvon", Woman )
    , ( "Dael Harker", Man )
    , ( "Hickory Dock", Man )
    , ( "Athena", Woman )
    , ( "Oriz Gibbs", Man )
    ]
        |> List.filterMap
            (\( text, voice ) ->
                case Name.fromString text of
                    Ok name ->
                        Just ( name, voice )

                    Err _ ->
                        Nothing
            )
        |> List.Nonempty.fromList
        |> Maybe.withDefault (Nonempty ( Name.sven, OldMan ) [])


randomSkinColor : Random.Generator Color
randomSkinColor =
    Random.weighted
        ( 0.2, Color.rgb255 255 245 120 )
        [ ( 0.2, Color.rgb255 200 180 50 )
        , ( 0.2, Color.rgb255 150 100 0 )
        , ( 0.2, Color.rgb255 80 70 0 )
        , ( 0.05, Color.rgb255 250 250 30 )
        , ( 0.05, Color.rgb255 250 200 230 )
        , ( 0.05, Color.rgb255 150 180 230 )
        , ( 0.05, Color.rgb255 20 230 20 )
        ]


randomClothColor : Random.Generator Color
randomClothColor =
    Random.weighted
        ( 0.05, Color.rgb255 255 230 230 )
        [ ( 0.05, Color.rgb255 150 150 150 )
        , ( 0.05, Color.rgb255 80 80 80 )
        , ( 0.05, Color.rgb255 150 180 255 )
        , ( 0.05, Color.rgb255 157 225 157 )
        , ( 0.05, Color.rgb255 250 250 250 )
        , ( 0.05, Color.rgb255 255 245 247 )
        , ( 0.05, Color.rgb255 245 247 255 )
        , ( 0.05, Color.rgb255 255 137 10 )
        ]
