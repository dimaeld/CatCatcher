import SpriteKit
import SwiftUI
import AVFoundation

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
        let topLayer = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 0.6))
        topLayer.fillColor = SKColor(red: 0.55, green: 0.85, blue: 1.0, alpha: 1.0)
        topLayer.strokeColor = .clear
        topLayer.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        topLayer.zPosition = -10
        topLayer.alpha = 1.0
        addChild(topLayer)

        let bottomLayer = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 0.7))
        bottomLayer.fillColor = SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
        bottomLayer.strokeColor = .clear
        bottomLayer.position = CGPoint(x: size.width / 2, y: size.height * 0.35)
        bottomLayer.zPosition = -11
        addChild(bottomLayer)

        let moveLeft = SKAction.moveBy(x: -40, y: 0, duration: 8)
        let moveRight = moveLeft.reversed()
        let seq = SKAction.sequence([moveLeft, moveRight])
        topLayer.run(SKAction.repeatForever(seq))
        bottomLayer.run(SKAction.repeatForever(SKAction.sequence([SKAction.moveBy(x: -15, y: 0, duration: 10), SKAction.moveBy(x: 15, y: 0, duration: 10)])))
    }

    private func addCat() {
        let catSize = CGSize(width: 80, height: 56)
        let catBody = SKShapeNode(roundedRectOf: catSize, cornerRadius: 18)
        catBody.fillColor = .orange
        catBody.strokeColor = .clear

        catNode = SKSpriteNode(color: .clear, size: catSize)
        catNode.zPosition = 1
        catNode.position = CGPoint(x: size.width / 2, y: max(catSize.height, 80))
        catNode.name = "cat"
        addChild(catNode)

        catBody.position = CGPoint(x: 0, y: 0)
        catNode.addChild(catBody)

        let label = SKLabelNode(text: "🐱")
        label.fontSize = 28
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint.zero
        catNode.addChild(label)

        catNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: catSize.width - 6, height: catSize.height - 10))
        catNode.physicsBody?.isDynamic = false
        catNode.physicsBody?.affectedByGravity = false
        catNode.physicsBody?.categoryBitMask = PhysicsCategory.cat
        catNode.physicsBody?.contactTestBitMask = PhysicsCategory.good | PhysicsCategory.bad
        catNode.physicsBody?.collisionBitMask = 0
    }

    private func spawnItem() {
        let isGood = Bool.random(probability: goodProbability(score: gameState.score))
        let x = CGFloat.random(in: 24...(size.width - 24))
        let startY = size.height + 40

        let container = SKNode()
        container.position = CGPoint(x: x, y: startY)
        container.zPosition = 5

        let radius: CGFloat = isGood ? CGFloat.random(in: 18...26) : CGFloat.random(in: 22...30)
        let shape = SKShapeNode(circleOfRadius: radius)
        shape.fillColor = isGood ? SKColor.systemTeal : SKColor.systemGray
        shape.strokeColor = .clear
        shape.alpha = 1.0
        container.addChild(shape)

        let emojisGood = ["🐟", "🍣", "🪙"]
        let emojisBad = ["💣", "👢", "🗑️"]
        let emoji = SKLabelNode(text: isGood ? emojisGood.randomElement()! : emojisBad.randomElement()!)
        emoji.fontSize = radius
        emoji.verticalAlignmentMode = .center
        emoji.horizontalAlignmentMode = .center
        emoji.position = CGPoint.zero
        container.addChild(emoji)

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

        enumerateChildNodes(withName: "//") { node, _ in
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
