import Foundation

public struct Position: Comparable {
    public var x: Int!
    public var y: Int!
    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    public static func < (lhs: Position, rhs: Position) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

public class Pathfinding {
    private class CellNode: Hashable {
        var parent: CellNode?
        var position: Position
        var f: Double
        var g: Double
        var h: Double

        init(parent: CellNode?, position: Position) {
            self.parent = parent
            self.position = position
            f = 0
            g = 0
            h = 0
        }

        static func == (lhs: CellNode, rhs: CellNode) -> Bool {
            return lhs.position.x == rhs.position.x && lhs.position.y == rhs.position.y
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(position.x)
            hasher.combine(position.y)
        }
    }

    private static func isWalkableTileForTileCoord(grid: [[Int]], position: Position, delta: Position) -> (Bool, Position) {
        let new_position = Position(position.x + delta.x, position.y + delta.y)
        if new_position.x > (grid.count - 1) ||
            new_position.x < 0 ||
            new_position.y > (grid[grid.count - 1].count - 1) ||
            new_position.y < 0
        { return (false, new_position) }

        if grid[new_position.x][new_position.y] == 1 { return (false, new_position) }
        return (true, new_position)
    }

    private static func walkableAdjacentTilesCoordsForTileCoord(grid: [[Int]], current_node: CellNode) -> [CellNode] {
        let canMoveUp = isWalkableTileForTileCoord(grid: grid, position: current_node.position, delta: Position(0, 1))
        let canMoveLeft = isWalkableTileForTileCoord(grid: grid, position: current_node.position, delta: Position(-1, 0))
        let canMoveDown = isWalkableTileForTileCoord(grid: grid, position: current_node.position, delta: Position(0, -1))
        let canMoveRight = isWalkableTileForTileCoord(grid: grid, position: current_node.position, delta: Position(1, 0))

        let canMoveTopRight = isWalkableTileForTileCoord(grid: grid, position: current_node.position, delta: Position(1, 1))
        let canMoveBottemRight = isWalkableTileForTileCoord(grid: grid, position: current_node.position, delta: Position(1, -1))
        let canMoveBottemLeft = isWalkableTileForTileCoord(grid: grid, position: current_node.position, delta: Position(-1, -1))
        let canMoveTopLeft = isWalkableTileForTileCoord(grid: grid, position: current_node.position, delta: Position(-1, 1))

        var walkableCoords = [CellNode]()

        if canMoveUp.0 {
            walkableCoords.append(CellNode(parent: current_node, position: canMoveUp.1))
        }
        if canMoveLeft.0 {
            walkableCoords.append(CellNode(parent: current_node, position: canMoveLeft.1))
        }
        if canMoveDown.0 {
            walkableCoords.append(CellNode(parent: current_node, position: canMoveDown.1))
        }
        if canMoveRight.0 {
            walkableCoords.append(CellNode(parent: current_node, position: canMoveRight.1))
        }

        // now the diagonals.
        if canMoveUp.0, canMoveLeft.0, canMoveTopLeft.0 {
            walkableCoords.append(CellNode(parent: current_node, position: canMoveTopLeft.1))
        }
        if canMoveDown.0, canMoveLeft.0, canMoveBottemLeft.0 {
            walkableCoords.append(CellNode(parent: current_node, position: canMoveBottemLeft.1))
        }
        if canMoveUp.0, canMoveRight.0, canMoveTopRight.0 {
            walkableCoords.append(CellNode(parent: current_node, position: canMoveTopRight.1))
        }
        if canMoveDown.0, canMoveRight.0, canMoveBottemRight.0 {
            walkableCoords.append(CellNode(parent: current_node, position: canMoveBottemRight.1))
        }

        return walkableCoords
    }

    public static func aStarPath(map: [[Int]], start: Position, end: Position) -> [Position] {
        if map.count < 1 || map.first == nil {
            print("map is invalid")
            return []
        }

        func isValid(_ row: Int, _ col: Int) -> Bool {
            return (row >= 0) && (row < map.count)
                && (col >= 0) && (col < map.first!.count)
        }

        // If the source is out of range.
        if !isValid(start.x, start.y) {
            print("Source is invalid")
            return []
        }

        // If the destination is out of range.
        if !isValid(end.x, end.y) {
            print("Destination is invalid")
            return []
        }

        // Either the source or the destination is blocked.
        if map[start.x][start.y] == 1 || map[end.x][end.y] == 1 {
            print("Source or the destination is blocked")
            return []
        }

        // If the destination cell is the same as source cell.
        if end == start {
            print("We are already at the destination")
            return []
        }
        // Create start and end node.
        let start_node = CellNode(parent: nil, position: start)
        start_node.g = 0
        start_node.h = 0
        start_node.f = 0
        let end_node = CellNode(parent: nil, position: end)
        end_node.g = 0
        end_node.h = 0
        end_node.f = 0

        //  Initialize both open and closed list.
        var open_list = [CellNode]()
        var closed_list = [CellNode]()

        // Add the start node.
        open_list.append(start_node)

        // Loop until you find the end.
        while open_list.count > 0 {
            var current_node = open_list[0]
            var current_index = 0

            // Get the current node.
            for (index, item) in open_list.enumerated() {
                if item.f < current_node.f {
                    current_node = item
                    current_index = index
                }
            }

            // Pop current off open list, add to closed list.
            open_list.remove(at: current_index)
            closed_list.append(current_node)
            if closed_list.count > map.count * map.first!.count * 2 {
                break
            }

            // Found the goal.
            if current_node == end_node {
                var path = [Position]()
                var current: CellNode? = current_node
                while current != nil {
                    path.append(current!.position)
                    current = current!.parent
                }
                return path.reversed()
            }

            // Generate children.
            let children = walkableAdjacentTilesCoordsForTileCoord(grid: map, current_node: current_node)

            for _child in children {
                let child = _child

                // Child is on the closed list.
                for closed_child in closed_list {
                    if child == closed_child {
                        continue
                    }
                }
                // Create the f, g, and h values.
                let knownspace = map[child.position.x][child.position.y] == 2 ? 3.0 : 0.0
                child.g = current_node.g + 1
                child.h = sqrt(Double(pow(Double(child.position.x - end_node.position.x), 2) + pow(Double(child.position.y - end_node.position.y), 2)))
                child.f = child.g + child.h + knownspace

                // Child is already in the open list.
                for open_node in open_list {
                    if child == open_node, child.g > open_node.g { continue }
                }

                // Add the child to the open list.
                open_list.append(child)
            }
        }
        print("We did not managed to find a path")
        return []
    }
}
