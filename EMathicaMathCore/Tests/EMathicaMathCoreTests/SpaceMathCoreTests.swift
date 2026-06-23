import Testing
@testable import EMathicaMathCore

struct SpaceMathCoreTests {
    private let epsilon = 1e-6

    @Test func vectorAddSubtract() {
        let a = Vector3D(x: 1, y: 2, z: 3)
        let b = Vector3D(x: -4, y: 5, z: 6)
        #expect(a + b == Vector3D(x: -3, y: 7, z: 9))
        #expect(a - b == Vector3D(x: 5, y: -3, z: -3))
    }

    @Test func dotAndCross() {
        let x = Vector3D(x: 1, y: 0, z: 0)
        let y = Vector3D(x: 0, y: 1, z: 0)
        #expect(abs(x.dot(y)) < epsilon)
        #expect(x.cross(y) == Vector3D(x: 0, y: 0, z: 1))
    }

    @Test func lengthNormalizedDistance() {
        let v = Vector3D(x: 3, y: 4, z: 12)
        #expect(abs(v.length - 13) < epsilon)
        let n = v.normalized()
        #expect(abs(n.length - 1) < 1e-5)

        let p1 = WorldPoint3D(x: 1, y: 2, z: 3)
        let p2 = WorldPoint3D(x: 4, y: 6, z: 3)
        #expect(abs(p1.distance(to: p2) - 5) < epsilon)
    }

    @Test func normalizedZeroVectorIsSafe() {
        #expect(Vector3D.zero.normalized() == .zero)
    }

    @Test func defaultCameraBasisIsFiniteAndOrthogonal() {
        let camera = SpaceCameraState.default
        let f = camera.forward
        let r = camera.right
        let u = camera.up
        #expect(f.length.isFinite)
        #expect(r.length.isFinite)
        #expect(u.length.isFinite)
        #expect(abs(f.dot(r)) < 1e-5)
        #expect(abs(f.dot(u)) < 1e-5)
        #expect(abs(r.dot(u)) < 1e-5)
    }

    @Test func pitchAndDistanceClampWork() {
        let c = SpaceCameraState(
            target: .zero,
            distance: -100,
            yaw: 0,
            pitch: .pi,
            projection: .perspective,
            fovDegrees: 60
        )
        #expect(c.clampedDistance >= SpaceCameraState.minDistance)
        #expect(c.clampedPitch <= SpaceCameraState.maxPitch)
        #expect(abs(SpaceCameraState.maxPitch) < (.pi / 2))
        #expect(abs(SpaceCameraState.maxPitch) <= (85.0 * .pi / 180.0 + 1e-9))
    }

    @Test func repeatedOrbitStaysFiniteNearPitchLimit() {
        var camera = SpaceCameraState.default
        for _ in 0..<2_000 {
            camera = camera.orbit(deltaYaw: 0.001, deltaPitch: 0.01)
        }
        #expect(camera.pitch <= SpaceCameraState.maxPitch)
        #expect(camera.forward.length.isFinite)
        #expect(camera.right.length.isFinite)
        #expect(camera.up.length.isFinite)
    }

    @Test func projectionAtCenterAndDirection() {
        let camera = SpaceCameraState.default
        let viewport = SpaceViewportSize(width: 1000, height: 600)
        let center = camera.project(camera.target, viewportSize: viewport)
        #expect(center.isVisible)
        #expect(abs(center.x - 500) < 1e-4)
        #expect(abs(center.y - 300) < 1e-4)

        let rightPoint = camera.target + camera.right
        let projectedRight = camera.project(rightPoint, viewportSize: viewport)
        #expect(projectedRight.x > center.x)

        let upPoint = camera.target + camera.up
        let projectedUp = camera.project(upPoint, viewportSize: viewport)
        #expect(projectedUp.y < center.y)
    }

    @Test func depthAndPerspectiveDistanceEffect() {
        let camera = SpaceCameraState.default
        let viewport = SpaceViewportSize(width: 1200, height: 800)
        let nearPoint = camera.target + camera.forward * 1
        let farPoint = camera.target + camera.forward * 4
        let nearProjected = camera.project(nearPoint, viewportSize: viewport)
        let farProjected = camera.project(farPoint, viewportSize: viewport)
        #expect(nearProjected.depth < farProjected.depth)

        let offset = camera.right * 2
        let nearOffsetProjected = camera.project(nearPoint + offset, viewportSize: viewport)
        let farOffsetProjected = camera.project(farPoint + offset, viewportSize: viewport)
        let center = camera.project(camera.target, viewportSize: viewport)
        #expect(abs(nearOffsetProjected.x - center.x) > abs(farOffsetProjected.x - center.x))
    }

    @Test func orthographicScreenXYStableAcrossDepth() {
        var camera = SpaceCameraState.default
        camera.projection = .orthographic
        let viewport = SpaceViewportSize(width: 1000, height: 600)
        let base = camera.target + camera.right * 2 + camera.up * 1
        let p1 = camera.project(base + camera.forward * 1, viewportSize: viewport)
        let p2 = camera.project(base + camera.forward * 10, viewportSize: viewport)
        #expect(abs(p1.x - p2.x) < 1e-6)
        #expect(abs(p1.y - p2.y) < 1e-6)
    }

    @Test func orbitPanZoomHelpers() {
        let camera = SpaceCameraState.default
        let orbited = camera.orbit(deltaYaw: 0.3, deltaPitch: -0.2)
        #expect(abs(orbited.yaw - (camera.yaw + 0.3)) < epsilon)
        #expect(abs(orbited.pitch - (camera.pitch - 0.2)) < epsilon)

        let panned = camera.pan(deltaX: 1.5, deltaY: -2.0)
        #expect(panned.target != camera.target)

        let zoomed = camera.zoom(delta: -1000)
        #expect(zoomed.distance >= SpaceCameraState.minDistance)
    }
}
