import SpriteKit
import SwiftUI
import AVFoundation
import UIKit

fileprivate struct PhysicsCategory {
    static let cat: UInt32 = 0x1 << 0
    static let good: UInt32 = 0x1 << 1
    static let bad: UInt32 = 0x1 << 2
}

final class GameScene: SKScene, SKPhysicsContactDelegate {
    unowned let gameState: GameState

    private var catNode: SKSpriteNode!

    private var lastSpawnTime: TimeInterval = 0
    private var spawnInterval: TimeInterval = 1.2
    private let minSpawnInterval: TimeInterval = 0.35

    private var lastUpdateTime: TimeInterval = 0

    private let catchSoundName = "catch.wav"
    private let badSoundName = "boom.wav"

    init(size: CGSize, gameState: GameState) {
        self.gameState = gameState
        super.init(size: size)
        self.scaleMode = .resizeFill
        setupScene()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    private func setupScene() {
        backgroundColor = SKColor.clear
        physicsWorld.gravity = CGVector(dx: 0, dy: -3.0)
        physicsWorld.contactDelegate = self
        addBackgroundLayers()
        addCat()
        lastSpawnTime = 0
        spawnInterval = 1.2
        lastUpdateTime = 0
    }

    private func addBackgroundLayers() {
        let sky = SKSpriteNode(texture: gradientTexture(size: CGSize(width: size.width, height: size.height),
                                                       colors: [UIColor(red: 0.25, green: 0.55, blue: 0.95, alpha: 1),
                                                                UIColor(red: 0.74, green: 0.9, blue: 1.0, alpha: 1)],
                                                       startPoint: CGPoint(x: 0.5, y: 1.0),
                                                       endPoint: CGPoint(x: 0.5, y: 0.0)))
        sky.size = CGSize(width: size.width * 1.1, height: size.height * 1.2)
        sky.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sky.zPosition = -20
        sky.alpha = 1.0
        addChild(sky)

        let farHills = createHillNode(width: size.width * 1.6,
                                      height: size.height * 0.35,
                                      color: SKColor(red: 0.59, green: 0.78, blue: 0.98, alpha: 1),
                                      blur: 14)
        farHills.position = CGPoint(x: size.width / 2, y: size.height * 0.15)
        farHills.zPosition = -15
        addChild(farHills)

        let midHills = createHillNode(width: size.width * 1.7,
                                      height: size.height * 0.42,
                                      color: SKColor(red: 0.48, green: 0.7, blue: 0.95, alpha: 1),
                                      blur: 10)
        midHills.position = CGPoint(x: size.width / 2, y: size.height * 0.12)
        midHills.zPosition = -12
        addChild(midHills)

        let grass = SKSpriteNode(texture: gradientTexture(size: CGSize(width: size.width * 1.3, height: size.height * 0.3),
                                                          colors: [UIColor(red: 0.22, green: 0.74, blue: 0.61, alpha: 1),
                                                                   UIColor(red: 0.1, green: 0.55, blue: 0.45, alpha: 1)],
                                                          startPoint: CGPoint(x: 0.5, y: 1),
                                                          endPoint: CGPoint(x: 0.5, y: 0)))
        grass.anchorPoint = CGPoint(x: 0.5, y: 0)
        grass.position = CGPoint(x: size.width / 2, y: -size.height * 0.02)
        grass.zPosition = -10
        addChild(grass)

        addClouds(count: 4)
    }

    private func gradientTexture(size: CGSize, colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = CGRect(origin: .zero, size: size)
            gradientLayer.colors = colors.map { $0.cgColor }
            gradientLayer.startPoint = startPoint
            gradientLayer.endPoint = endPoint
            gradientLayer.render(in: context.cgContext)
        }
        return SKTexture(image: image)
    }

    private func createHillNode(width: CGFloat, height: CGFloat, color: SKColor, blur: CGFloat) -> SKNode {
        let hill = SKShapeNode(circleOfRadius: width / 2)
        hill.xScale = 1.8
        hill.yScale = height / width
        hill.fillColor = color
        hill.strokeColor = .clear
        hill.alpha = 0.9

        let effect = SKEffectNode()
        effect.shouldRasterize = true
        effect.addChild(hill)
        effect.filter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: blur])
        effect.zPosition = hill.zPosition
        return effect
    }

    private func addClouds(count: Int) {
        for i in 0..<count {
            let width = CGFloat.random(in: size.width * 0.28...size.width * 0.38)
            let height = width * 0.45
            let yPosition = size.height * (0.65 + CGFloat.random(in: -0.05...0.08))
            let cloud = createCloud(size: CGSize(width: width, height: height))
            cloud.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: yPosition)
            cloud.zPosition = -9 - CGFloat(i)
            addChild(cloud)

            let drift = SKAction.sequence([
                SKAction.moveBy(x: 30, y: 0, duration: 10 + Double.random(in: -2...2)),
                SKAction.moveBy(x: -30, y: 0, duration: 10 + Double.random(in: -2...2))
            ])
            cloud.run(SKAction.repeatForever(drift))
        }
    }

    private func createCloud(size: CGSize) -> SKNode {
        let cloud = SKNode()
        let base = SKShapeNode(rectOf: size, cornerRadius: size.height / 2)
        base.fillColor = SKColor.white.withAlphaComponent(0.9)
        base.strokeColor = .clear
        cloud.addChild(base)

        let puff1 = SKShapeNode(circleOfRadius: size.height * 0.55)
        puff1.fillColor = SKColor.white.withAlphaComponent(0.95)
        puff1.strokeColor = .clear
        puff1.position = CGPoint(x: -size.width * 0.25, y: size.height * 0.15)
        cloud.addChild(puff1)

        let puff2 = SKShapeNode(circleOfRadius: size.height * 0.5)
        puff2.fillColor = SKColor.white.withAlphaComponent(0.95)
        puff2.strokeColor = .clear
        puff2.position = CGPoint(x: size.width * 0.1, y: size.height * 0.2)
        cloud.addChild(puff2)

        let puff3 = SKShapeNode(circleOfRadius: size.height * 0.45)
        puff3.fillColor = SKColor.white
        puff3.strokeColor = .clear
        puff3.position = CGPoint(x: size.width * 0.32, y: size.height * 0.08)
        cloud.addChild(puff3)

        cloud.alpha = 0.88
        return cloud
    }

    private func addCat() {
        let catSize = CGSize(width: 90, height: 62)
        catNode = SKSpriteNode(color: .clear, size: catSize)
        catNode.zPosition = 1
        catNode.position = CGPoint(x: size.width / 2, y: max(catSize.height, 90))
        catNode.name = "cat"
        addChild(catNode)

        let body = SKShapeNode(roundedRectOf: catSize, cornerRadius: 22)
        body.fillTexture = gradientTexture(size: catSize,
                                           colors: [UIColor(red: 1.0, green: 0.78, blue: 0.45, alpha: 1),
                                                    UIColor(red: 0.98, green: 0.6, blue: 0.2, alpha: 1)],
                                           startPoint: CGPoint(x: 0.2, y: 1.0),
                                           endPoint: CGPoint(x: 0.9, y: 0.0))
        body.fillColor = .orange
        body.strokeColor = SKColor(red: 0.91, green: 0.56, blue: 0.15, alpha: 1)
        body.lineWidth = 2
        body.position = CGPoint.zero
        catNode.addChild(body)

        let belly = SKShapeNode(ellipseOf: CGSize(width: catSize.width * 0.62, height: catSize.height * 0.7))
        belly.fillTexture = gradientTexture(size: belly.frame.size,
                                            colors: [UIColor(red: 1, green: 0.92, blue: 0.83, alpha: 1),
                                                     UIColor(red: 0.99, green: 0.82, blue: 0.6, alpha: 1)],
                                            startPoint: CGPoint(x: 0.5, y: 1),
                                            endPoint: CGPoint(x: 0.5, y: 0))
        belly.fillColor = .white
        belly.strokeColor = SKColor(red: 0.95, green: 0.83, blue: 0.69, alpha: 1)
        belly.lineWidth = 1.5
        belly.position = CGPoint(x: 0, y: -6)
        catNode.addChild(belly)

        let earLeft = createEar(angle: 0.3)
        earLeft.position = CGPoint(x: -catSize.width * 0.26, y: catSize.height * 0.3)
        catNode.addChild(earLeft)

        let earRight = createEar(angle: -0.3)
        earRight.position = CGPoint(x: catSize.width * 0.26, y: catSize.height * 0.3)
        catNode.addChild(earRight)

        let faceMask = SKShapeNode(circleOfRadius: catSize.height * 0.25)
        faceMask.fillTexture = gradientTexture(size: CGSize(width: catSize.height * 0.5, height: catSize.height * 0.5),
                                               colors: [UIColor(red: 1, green: 0.85, blue: 0.6, alpha: 1),
                                                        UIColor(red: 1, green: 0.72, blue: 0.4, alpha: 1)],
                                               startPoint: CGPoint(x: 0.3, y: 1),
                                               endPoint: CGPoint(x: 0.7, y: 0))
        faceMask.fillColor = .white
        faceMask.strokeColor = SKColor(red: 0.95, green: 0.74, blue: 0.51, alpha: 1)
        faceMask.lineWidth = 1.5
        faceMask.position = CGPoint(x: 0, y: catSize.height * 0.05)
        catNode.addChild(faceMask)

        let eyeLeft = createEye()
        eyeLeft.position = CGPoint(x: -catSize.width * 0.16, y: catSize.height * 0.12)
        catNode.addChild(eyeLeft)

        let eyeRight = createEye()
        eyeRight.position = CGPoint(x: catSize.width * 0.16, y: catSize.height * 0.12)
        catNode.addChild(eyeRight)

        let nose = SKShapeNode(path: nosePath())
        nose.fillColor = SKColor(red: 0.98, green: 0.48, blue: 0.55, alpha: 1)
        nose.strokeColor = SKColor(red: 0.75, green: 0.23, blue: 0.32, alpha: 1)
        nose.lineWidth = 1.2
        nose.position = CGPoint(x: 0, y: catSize.height * 0.04)
        catNode.addChild(nose)

        addWhiskers()

        let shine = SKShapeNode(circleOfRadius: 8)
        shine.fillColor = SKColor.white.withAlphaComponent(0.24)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: catSize.width * 0.28, y: catSize.height * 0.2)
        shine.zRotation = -0.2
        catNode.addChild(shine)

        catNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: catSize.width - 6, height: catSize.height - 10))
        catNode.physicsBody?.isDynamic = false
        catNode.physicsBody?.affectedByGravity = false
        catNode.physicsBody?.categoryBitMask = PhysicsCategory.cat
        catNode.physicsBody?.contactTestBitMask = PhysicsCategory.good | PhysicsCategory.bad
        catNode.physicsBody?.collisionBitMask = 0
    }

    private func createEar(angle: CGFloat) -> SKNode {
        let earSize = CGSize(width: 26, height: 30)
        let earPath = UIBezierPath()
        earPath.move(to: CGPoint(x: -earSize.width / 2, y: -earSize.height / 2))
        earPath.addLine(to: CGPoint(x: earSize.width / 2, y: -earSize.height / 2))
        earPath.addLine(to: CGPoint(x: 0, y: earSize.height / 2))
        earPath.close()

        let outer = SKShapeNode(path: earPath.cgPath)
        outer.fillTexture = gradientTexture(size: earSize,
                                            colors: [UIColor(red: 1.0, green: 0.82, blue: 0.53, alpha: 1),
                                                     UIColor(red: 0.95, green: 0.58, blue: 0.15, alpha: 1)],
                                            startPoint: CGPoint(x: 0.5, y: 1),
                                            endPoint: CGPoint(x: 0.5, y: 0))
        outer.fillColor = .orange
        outer.strokeColor = SKColor(red: 0.93, green: 0.61, blue: 0.22, alpha: 1)
        outer.lineWidth = 1.5

        let inner = SKShapeNode(path: earPath.insetBy(dx: 4, dy: 4).cgPath)
        inner.fillColor = SKColor(red: 0.99, green: 0.75, blue: 0.77, alpha: 1)
        inner.strokeColor = SKColor(red: 0.78, green: 0.34, blue: 0.37, alpha: 1)
        inner.lineWidth = 1.2
        inner.position = CGPoint(x: 0, y: 2)

        let ear = SKNode()
        ear.zRotation = angle
        ear.addChild(outer)
        ear.addChild(inner)
        return ear
    }

    private func createEye() -> SKNode {
        let eye = SKNode()
        let white = SKShapeNode(circleOfRadius: 9)
        white.fillColor = SKColor.white
        white.strokeColor = SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        white.lineWidth = 1
        eye.addChild(white)

        let iris = SKShapeNode(circleOfRadius: 5)
        iris.fillColor = SKColor(red: 0.11, green: 0.59, blue: 0.49, alpha: 1)
        iris.strokeColor = SKColor(red: 0.05, green: 0.38, blue: 0.32, alpha: 1)
        iris.lineWidth = 1
        iris.position = CGPoint(x: 0, y: -1)
        eye.addChild(iris)

        let pupil = SKShapeNode(circleOfRadius: 2.5)
        pupil.fillColor = .black
        pupil.strokeColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        pupil.lineWidth = 1
        pupil.position = CGPoint(x: 0, y: -1)
        eye.addChild(pupil)

        let sparkle = SKShapeNode(circleOfRadius: 1.5)
        sparkle.fillColor = SKColor.white
        sparkle.strokeColor = .clear
        sparkle.position = CGPoint(x: 2.5, y: 1.5)
        eye.addChild(sparkle)

        return eye
    }

    private func nosePath() -> CGPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -6, y: 4))
        path.addLine(to: CGPoint(x: 6, y: 4))
        path.addLine(to: CGPoint(x: 0, y: -4))
        path.close()
        return path.cgPath
    }

    private func addWhiskers() {
        guard let catNode else { return }
        let offsets: [CGFloat] = [6, -2, -10]
        let length: CGFloat = 32
        for offset in offsets {
            let leftPath = UIBezierPath()
            leftPath.move(to: CGPoint(x: -8, y: offset))
            leftPath.addLine(to: CGPoint(x: -length, y: offset + 2))
            let leftWhisker = SKShapeNode(path: leftPath.cgPath)
            leftWhisker.strokeColor = SKColor(red: 0.8, green: 0.52, blue: 0.22, alpha: 1)
            leftWhisker.lineWidth = 2
            leftWhisker.lineCap = .round
            catNode.addChild(leftWhisker)

            let rightPath = UIBezierPath()
            rightPath.move(to: CGPoint(x: 8, y: offset))
            rightPath.addLine(to: CGPoint(x: length, y: offset + 2))
            let rightWhisker = SKShapeNode(path: rightPath.cgPath)
            rightWhisker.strokeColor = SKColor(red: 0.8, green: 0.52, blue: 0.22, alpha: 1)
            rightWhisker.lineWidth = 2
            rightWhisker.lineCap = .round
            catNode.addChild(rightWhisker)
        }
    }

    private func spawnItem() {
        let isGood = Bool.random(probability: goodProbability(score: gameState.score))
        let x = CGFloat.random(in: 24...(size.width - 24))
        let startY = size.height + 40

        let container = SKNode()
        container.position = CGPoint(x: x, y: startY)
        container.zPosition = 5

        let radius: CGFloat = isGood ? CGFloat.random(in: 18...26) : CGFloat.random(in: 22...30)
        let itemNode = createItemNode(radius: radius, isGood: isGood)
        container.addChild(itemNode)

        container.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        container.physicsBody?.isDynamic = true
        container.physicsBody?.affectedByGravity = true
        container.physicsBody?.mass = isGood ? 0.08 : 0.12
        container.physicsBody?.categoryBitMask = isGood ? PhysicsCategory.good : PhysicsCategory.bad
        container.physicsBody?.contactTestBitMask = PhysicsCategory.cat
        container.physicsBody?.collisionBitMask = 0
        container.name = isGood ? "good" : "bad"

        addChild(container)

        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 10),
            SKAction.removeFromParent()
        ])
        container.run(removeAction)
    }

    private func createItemNode(radius: CGFloat, isGood: Bool) -> SKNode {
        let node = SKNode()
        let colors: [UIColor]
        let stroke: SKColor
        let iconChoices: [String]

        if isGood {
            colors = [UIColor(red: 0.27, green: 0.91, blue: 0.86, alpha: 1),
                      UIColor(red: 0.14, green: 0.61, blue: 0.93, alpha: 1)]
            stroke = SKColor(red: 0.05, green: 0.55, blue: 0.65, alpha: 1)
            iconChoices = ["🐟", "🍣", "🪙"]
        } else {
            colors = [UIColor(red: 0.25, green: 0.29, blue: 0.36, alpha: 1),
                      UIColor(red: 0.1, green: 0.12, blue: 0.17, alpha: 1)]
            stroke = SKColor(red: 0.96, green: 0.38, blue: 0.33, alpha: 1)
            iconChoices = ["💣", "👢", "🗑️"]
        }

        let badge = SKShapeNode(circleOfRadius: radius)
        badge.fillTexture = gradientTexture(size: CGSize(width: radius * 2, height: radius * 2),
                                           colors: colors,
                                           startPoint: CGPoint(x: 0.5, y: 1),
                                           endPoint: CGPoint(x: 0.5, y: 0))
        badge.fillColor = .white
        badge.strokeColor = stroke
        badge.lineWidth = 3
        node.addChild(badge)

        let shine = SKShapeNode(ellipseOf: CGSize(width: radius, height: radius * 0.55))
        shine.fillColor = SKColor.white.withAlphaComponent(0.28)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -radius * 0.2, y: radius * 0.2)
        node.addChild(shine)

        let ring = SKShapeNode(circleOfRadius: radius + 4)
        ring.strokeColor = stroke.withAlphaComponent(0.35)
        ring.lineWidth = 2
        ring.alpha = 0.8
        node.addChild(ring)

        let emoji = SKLabelNode(text: iconChoices.randomElement() ?? "?")
        emoji.fontSize = radius
        emoji.verticalAlignmentMode = .center
        emoji.horizontalAlignmentMode = .center
        emoji.position = CGPoint.zero
        emoji.fontName = "AvenirNext-Bold"
        node.addChild(emoji)

        if isGood {
            node.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.4),
                SKAction.scale(to: 1.0, duration: 0.35)
            ])))
        } else {
            node.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.rotate(byAngle: 0.08, duration: 0.25),
                SKAction.rotate(byAngle: -0.08, duration: 0.25)
            ])))
        }

        return node
    }

    private func goodProbability(score: Int) -> Double {
        let start: Double = 0.70
        let reduced = max(0.35, start - Double(score) * 0.005)
        return reduced
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        if gameState.isPaused || gameState.isGameOver {
            self.isPaused = true
            return
        } else {
            self.isPaused = false
        }

        let difficultyFactor = min(1.0, Double(gameState.score) / 60.0)
        spawnInterval = 1.2 - (0.8 * difficultyFactor)
        spawnInterval = max(minSpawnInterval, spawnInterval)

        physicsWorld.gravity = CGVector(dx: 0, dy: -3.0 - CGFloat(Double(gameState.score) * 0.04))

        lastSpawnTime += delta
        if lastSpawnTime >= spawnInterval {
            lastSpawnTime = 0
            spawnItem()
        }

        enumerateChildNodes(withName: "//*") { node, _ in
            if node.position.y < -200 { node.removeFromParent() }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameState.isGameOver else { return }
        if let t = touches.first { moveCatByTouch(t) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let t = touches.first { moveCatByTouch(t) }
    }

    private func moveCatByTouch(_ touch: UITouch) {
        let location = touch.location(in: self)
        let distance = abs(location.x - catNode.position.x)
        let moveDuration = max(0.04, min(0.18, TimeInterval(distance / 1000)))
        let clampedX = min(max(location.x, 24), size.width - 24)
        let moveAction = SKAction.moveTo(x: clampedX, duration: moveDuration)
        moveAction.timingMode = .easeOut
        catNode.run(moveAction)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else { return }

        var itemNode: SKNode?
        if contact.bodyA.categoryBitMask == PhysicsCategory.cat {
            itemNode = nodeB
        } else if contact.bodyB.categoryBitMask == PhysicsCategory.cat {
            itemNode = nodeA
        } else { return }

        guard let item = itemNode else { return }
        if item.parent == nil { return }

        if item.name == "good" { handleGoodHit(itemNode: item) }
        else if item.name == "bad" { handleBadHit(itemNode: item) }
    }

    private func handleGoodHit(itemNode: SKNode) {
        gameState.addPoints(1)

        let pop = SKAction.group([
            SKAction.scale(to: 1.6, duration: 0.12),
            SKAction.fadeAlpha(to: 0.0, duration: 0.22)
        ])
        itemNode.run(pop) { itemNode.removeFromParent() }

        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.06, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])
        catNode.run(bounce)

        let scoreLabel = SKLabelNode(text: "+1")
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .yellow
        scoreLabel.position = CGPoint(x: itemNode.position.x, y: itemNode.position.y)
        scoreLabel.zPosition = 1000
        addChild(scoreLabel)
        scoreLabel.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 40, duration: 0.7),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        spawnCatchParticles(at: itemNode.position, color: .yellow)

        run(SKAction.playSoundFileNamed(catchSoundName, waitForCompletion: false))
    }

    private func handleBadHit(itemNode: SKNode) {
        gameState.loseLife()

        let pop = SKAction.group([
            SKAction.scale(to: 1.4, duration: 0.12),
            SKAction.fadeAlpha(to: 0.0, duration: 0.2)
        ])
        itemNode.run(pop) { itemNode.removeFromParent() }

        let moveLeft = SKAction.moveBy(x: -10, y: 0, duration: 0.05)
        let moveRight = moveLeft.reversed()
        let shake = SKAction.sequence([moveLeft, moveRight, moveRight, moveLeft])
        catNode.run(shake)

        let flash = SKAction.sequence([SKAction.run { [weak self] in
            guard let self = self else { return }
            let flashNode = SKSpriteNode(color: .red, size: self.size)
            flashNode.alpha = 0.0
            flashNode.zPosition = 9999
            self.addChild(flashNode)
            flashNode.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.14, duration: 0.06),
                SKAction.fadeOut(withDuration: 0.22),
                SKAction.removeFromParent()
            ]))
        }])
        run(flash)

        run(SKAction.playSoundFileNamed(badSoundName, waitForCompletion: false))
    }

    private func spawnCatchParticles(at position: CGPoint, color: SKColor) {
        let count = 8
        for i in 0..<count {
            let tiny = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            tiny.fillColor = color
            tiny.strokeColor = .clear
            tiny.zPosition = 1000
            tiny.position = position
            addChild(tiny)

            let angle = CGFloat(i) * (CGFloat.pi * 2.0 / CGFloat(count)) + CGFloat.random(in: -0.2...0.2)
            let distance = CGFloat.random(in: 16...48)
            let move = SKAction.moveBy(x: cos(angle) * distance, y: sin(angle) * distance + 8, duration: 0.5)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.5)
            tiny.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }
    }
}

fileprivate extension Bool {
    static func random(probability: Double) -> Bool {
        return Double.random(in: 0...1) < probability
    }
}
