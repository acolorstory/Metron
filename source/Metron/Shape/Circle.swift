import CoreGraphics

/**
 *  A `Circle` represented by a center and a radius.
 */
public struct Circle {

    /// The center of the circle.
    public var center: CGPoint

    /// The radius of the circle, i.e. the distance
    /// from the center to the edge of the circle.
    public var radius: CGFloat

    public init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }
}

public extension Circle {

    /// Initializes a `Circle` with radius equal to
    /// half of the provided diameter.
    public init(center: CGPoint, diameter: CGFloat) {
        self.init(center: center, radius: diameter / 2.0)
    }

    /// Initializes a `Circle` that is aspect-fitted
    /// in the center of the provided rect.
    public init(in rect: CGRect) {
        self.init(in: Square(in: rect))
    }

    /// Initializes a `Circle` that is fitted in the
    /// provided square.
    public init(in square: Square) {
        self.init(center: square.center, diameter: square.edges)
    }

    /// The diamater, equal to 2 times the radius.
    public var diameter: CGFloat {
        return radius * 2.0
    }

    /// The length of the enclosing boundary.
    public var circumference: CGFloat {
        return diameter * .pi
    }

    /// - returns: The bounding square for this circle.
    public var square: Square {
        return Square(origin: CGPoint(x: minX, y: minY), edges: diameter)
    }
}

public extension Circle {

    /// - returns: An array of CGPoints along the perimeter of this circle.
    /// The circle is divided into `segments`, which can also be a non-integer number.
    /// The points are taken `startingAt` a specific angle and `rotating` in a 
    /// specific direction (`clockwise` by default), .
    public func pointsAlongPerimeter(dividedInto segments: CGFloat, startingAt startingAngle: Angle = Angle(0), rotating: RotationDirection = .clockwise) -> [CGPoint] {
        guard segments > 0 else { return [] }
        let fullRotation = Angle.fullRotation(unit: .radians)
        let step = fullRotation / segments

        var offset: CGFloat = 0.0
        var points: [CGPoint] = []

        let steppingRunsClockwise = CoordinateSystem.default.circleRunsClockwise
        let shouldStepBackwards = steppingRunsClockwise != (rotating == .clockwise)

        while offset < fullRotation {
            let angle = shouldStepBackwards ? (startingAngle - Angle(offset)) : (startingAngle + Angle(offset))
            let vector = CGVector(angle: angle, magnitude: radius)
            let point = center + vector
            points.append(point)
            offset += step
        }

        return points
    }
}

public extension Circle {

    public func intersection(with line: Line) -> [CGPoint] {
        let minPoint = CGPoint(x: CGFloat.leastNormalMagnitude, y: CGFloat.leastNormalMagnitude)
        let maxPoint = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)

        let pointXA = line.point(atX: center.x - radius) ?? maxPoint
        let pointXB = line.point(atX: center.x + radius) ?? minPoint
        let pointYA = line.point(atY: center.y - radius) ?? maxPoint
        let pointYB = line.point(atY: center.y + radius) ?? minPoint

        let distX = pointXA.distance(to: pointXB)
        let distY = pointYA.distance(to: pointYB)

        let pointA = distX <= distY ? pointXA : pointYA
        let pointB = distX <= distY ? pointXB : pointYB

        let segment = LineSegment(a: pointA, b: pointB)

        return intersection(with: segment)
    }

    public func intersection(with lineSegment: LineSegment) -> [CGPoint] {
        let epsilon = 0.0001 as CGFloat
        let lineLength = lineSegment.length
        var normalizedLineVector = CGPoint(x: lineSegment.b.x - lineSegment.a.x,
                                           y: lineSegment.b.y - lineSegment.a.y)
        // normalize line vector

        normalizedLineVector.x /= lineLength
        normalizedLineVector.y /= lineLength

        let circleCenterVector = CGPoint(x: center.x - lineSegment.a.x,
                                         y: center.y - lineSegment.a.y)

        // dot product between line vector and circle center vector
        let circleLineDotProduct = circleCenterVector.x * normalizedLineVector.x + circleCenterVector.y * normalizedLineVector.y

        // project circle center onto line. This gives the closest point from the circle to the line
        var circleToLineProjection = normalizedLineVector
        circleToLineProjection.x *= circleLineDotProduct
        circleToLineProjection.y *= circleLineDotProduct

        // convert to "world" coordinates
        circleToLineProjection.x += lineSegment.a.x
        circleToLineProjection.y += lineSegment.a.y

        // circle and line intersect if the circle contains the projected point
        let distanceToCircle = circleToLineProjection.distance(to: center)
        if abs(distanceToCircle-radius) < epsilon { //ulpOfOne = epsilon
            if circleLineDotProduct >= 0 && circleLineDotProduct <= lineLength {
                return [circleToLineProjection]
            } else {
                return []
            }
        } else if distanceToCircle < radius {
            // two points
            let dt = sqrt(radius * radius - distanceToCircle * distanceToCircle)
            let t1 = circleLineDotProduct - dt
            let t2 = circleLineDotProduct + dt
            let inter1 = t1 >= 0 && (t1 < lineLength || (abs(t1-lineLength) < epsilon))
            let inter2 = t2 >= 0 && (t2 < lineLength || (abs(t2-lineLength) < epsilon))

            var i1: CGPoint = .zero
            var i2: CGPoint = .zero
            if inter1 {
                i1 = CGPoint(x: normalizedLineVector.x * t1 + lineSegment.a.x,
                             y: normalizedLineVector.y * t1 + lineSegment.a.y)
            }
            if inter2 {
                i2 = CGPoint(x: normalizedLineVector.x * t2 + lineSegment.a.x,
                             y: normalizedLineVector.y * t2 + lineSegment.a.y)
            }
            if(inter1 && inter2) {
                return [i1, i2]
            } else if(inter1) {
                return [i1]
            } else if(inter2) {
                return [i2];
            } else {
                return [];
            }
        } else {
            // no points
            return []
        }
    }
}

// MARK: Drawable

extension Circle: Drawable {
    public var path: CGPath? {
        return CGPath(ellipseIn: boundingRect, transform: nil)
    }
}

// MARK: Shape

extension Circle: Shape {

    public var area: CGFloat {
        return radius * radius * .pi
    }

    public var perimeter: CGFloat {
        return circumference
    }

    /// Extremities:
    public var minX: CGFloat { return center.x - radius }
    public var maxX: CGFloat { return center.x + radius }
    public var minY: CGFloat { return center.y - radius }
    public var maxY: CGFloat { return center.y + radius }

    /// Midpoints:
    public var midX: CGFloat { return center.x }
    public var midY: CGFloat { return center.y }

    public var width: CGFloat { return diameter }
    public var height: CGFloat { return diameter }

    /// The smallest rect in which the circle can be fitted.
    public var boundingRect: CGRect {
        return CGRect(center: center, edges: diameter)
    }

    public func contains(_ point: CGPoint) -> Bool {
        return center.distance(to: point) <= radius
    }
}

// MARK: Equatable / Comparable

extension Circle: Equatable {
    /// True if the radius is the same, regardless of center
    public static func ==(lhs: Circle, rhs: Circle) -> Bool {
        return lhs.radius == rhs.radius
    }
}

/// True if radius and center are the same
public func ===(lhs: Circle, rhs: Circle) -> Bool {
    return lhs.radius == rhs.radius &&
        lhs.center == rhs.center
}

extension Circle: Comparable {
    public static func <(lhs: Circle, rhs: Circle) -> Bool {
        return lhs.radius < rhs.radius
    }
}

// MARK: CustomDebugStringConvertible

extension Circle: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Circle {center: \(center), radius: \(radius)}"
    }
}
