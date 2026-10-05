import Data.Char (isSpace)

type Position = (Int, Int)
type Maze = [String]

-- Input format:
-- rows columns
-- rows lines containing '.' for a free cell and '#' for a wall
-- start_row start_column
-- finish_row finish_column
-- Coordinates are zero-based.
main :: IO ()
main = do
    input <- getContents
    let inputLines = filter (not . all isSpace) (lines input)
    case inputLines of
        sizeLine : rest -> runMaze sizeLine rest
        _ -> error "Input is empty"

runMaze :: String -> [String] -> IO ()
runMaze sizeLine rest = do
    let (rowCount, columnCount) = readPair sizeLine
    if rowCount <= 0 || columnCount <= 0
        then error "Maze dimensions must be positive"
        else return ()

    let maze = take rowCount rest
    if length maze /= rowCount || any ((/= columnCount) . length) maze
        then error "Invalid maze map"
        else return ()

    let coordinateLines = drop rowCount rest
    case coordinateLines of
        startLine : finishLine : _ -> do
            let start = readPair startLine
            let finish = readPair finishLine
            case findPath maze rowCount columnCount start finish of
                Nothing -> putStrLn "NO PATH"
                Just path -> do
                    putStrLn "PATH"
                    mapM_ printPosition path
        _ -> error "Start and finish coordinates are required"

readPair :: String -> (Int, Int)
readPair line =
    case map read (words line) of
        [first, second] -> (first, second)
        _ -> error "Expected two integers"

printPosition :: Position -> IO ()
printPosition (row, column) = putStrLn (show row ++ " " ++ show column)

findPath :: Maze -> Int -> Int -> Position -> Position -> Maybe [Position]
findPath maze rowCount columnCount start finish =
    fst (visit start [])
  where
    visit :: Position -> [Position] -> (Maybe [Position], [Position])
    visit position visited
        | not (isAvailable position visited) = (Nothing, visited)
        | position == finish = (Just [position], position : visited)
        | otherwise = search position (neighbors position) (position : visited)

    search :: Position -> [Position] -> [Position] -> (Maybe [Position], [Position])
    search _ [] visited = (Nothing, visited)
    search current (next : remaining) visited =
        case visit next visited of
            (Just path, updatedVisited) -> (Just (current : path), updatedVisited)
            (Nothing, updatedVisited) -> search current remaining updatedVisited

    isAvailable :: Position -> [Position] -> Bool
    isAvailable position@(row, column) visited =
        row >= 0
            && row < rowCount
            && column >= 0
            && column < columnCount
            && maze !! row !! column /= '#'
            && position `notElem` visited

    neighbors :: Position -> [Position]
    neighbors (row, column) =
        [ (row, column + 1)
        , (row + 1, column)
        , (row, column - 1)
        , (row - 1, column)
        ]
