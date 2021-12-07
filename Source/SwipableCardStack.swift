//
//  SwipableCardStack.swift
//  SwipableCardStack
//
//  Created by 윤재욱 on 2021/12/08.
//

import UIKit

protocol SwipableCardStackDataSource: NSObject {
    func numberOfCardsToShow() -> Int
    func card(at index: Int) -> SwipableCardView
}

protocol SwipableCardStackDelegate: NSObject {
    func cardDidSwiped(currentTopCard: SwipableCardView)
    func stackIsEmpty(isEmpty: Bool)
}

public class SwipableCardStack: UIView {
    
    private var numberOfCards: Int = 0
    private var currentIndex: Int = 0 {
        didSet {
            delegate?.stackIsEmpty(isEmpty: currentIndex == numberOfCards)
        }
    }
    private var cardViews : [SwipableCardView] = []
    private var visibleCards: [SwipableCardView] {
        return subviews as? [SwipableCardView] ?? []
    }
    
    private let numberOfLayers: Int = 3
    private var distance: CGFloat {
        return (self.frame.width - topCardViewSize.width) / CGFloat(numberOfLayers - 1)
    }
    private let differenceScale: CGFloat = 0.2
    private var topCardViewSize: CGSize {
        return self.frame.size.applying(CGAffineTransform(scaleX: 0.7, y: 1.0))
    }
    private var widthDifference: CGFloat {
        return topCardViewSize.width * differenceScale
    }
    private var heightDifference: CGFloat {
        return topCardViewSize.height * differenceScale
    }
    
    private var leftGesture: UISwipeGestureRecognizer!
    private var rightGesture: UISwipeGestureRecognizer!

    weak var dataSource: SwipableCardStackDataSource?
    weak var delegate: SwipableCardStackDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSwipeGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func reloadData() {
        removeAllCardViews()
        guard let datasource = dataSource else { return }
        setNeedsLayout()
        layoutIfNeeded()
        numberOfCards = datasource.numberOfCardsToShow()
        currentIndex = 0
        for i in 0..<min(numberOfLayers, numberOfCards) {
            addInitialCardView(cardView: datasource.card(at: i), atIndex: i )
        }
    }
    
    private func addInitialCardView(cardView: SwipableCardView, atIndex index: Int) {
        addInitialCardFrame(index: index, cardView: cardView)
        cardViews.append(cardView)
        insertSubview(cardView, at: 0)
    }
    
    private func addInitialCardFrame(index: Int, cardView: SwipableCardView) {
        cardView.frame.size = topCardViewSize.applying(
            CGAffineTransform(
                scaleX: 1 - (CGFloat(index) * differenceScale),
                y: 1 - (CGFloat(index) * differenceScale)
            )
        )
        cardView.frame.origin.x = CGFloat(index) * (widthDifference + distance)
        cardView.center.y = topCardViewSize.height / 2
    }
    
    private func removeAllCardViews() {
        for cardView in visibleCards {
            cardView.removeFromSuperview()
        }
        cardViews = []
    }
    
    private func addSwipeGesture() {
        self.isUserInteractionEnabled = true
        self.leftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        leftGesture.direction = .left
        self.addGestureRecognizer(leftGesture)
        self.rightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        rightGesture.direction = .right
        self.addGestureRecognizer(rightGesture)
    }
    
    @objc func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        guard let dataSource = self.dataSource,
              gesture.direction == .left || gesture.direction == .right else {return}
        
        switch gesture.direction {
        case .left:
            guard currentIndex < numberOfCards,
                  let currentFirstCard = cardViews.first,
                  let currentLastCardFrame = cardViews.last?.frame else {return}
            
            var newLastCard: SwipableCardView?
            
            if currentIndex + numberOfLayers < numberOfCards { //새로 들어올 카드 있을 때
                newLastCard = dataSource.card(at: currentIndex + numberOfLayers)
                newLastCard!.alpha = 0
                newLastCard!.frame.size = CGSize(
                    width: currentLastCardFrame.width - widthDifference,
                    height: currentLastCardFrame.height - heightDifference
                )
                newLastCard!.frame.origin.x = currentLastCardFrame.origin.x + widthDifference + distance
                newLastCard!.center.y = topCardViewSize.height / 2
                cardViews.append(newLastCard!)
                self.insertSubview(newLastCard!, at: 0)
                newLastCard!.layoutIfNeeded()
            }
            
            UIView.animate(withDuration: 0.3) {
                self.cardViews.enumerated().forEach { idx, card in
                    if card == currentFirstCard { //제일 왼쪽 카드 사라짐
                        
                        currentFirstCard.frame.size = self.topCardViewSize.applying(
                            CGAffineTransform(
                                scaleX: 1.0 + self.differenceScale,
                                y: 1.0 + self.differenceScale
                            )
                        )
                        currentFirstCard.frame.origin.x = -currentFirstCard.frame.width
                        currentFirstCard.center.y = self.topCardViewSize.height / 2
                        currentFirstCard.alpha = 0
                    } else if card == newLastCard { //오른쪽에서 새로 들어올 카드 이동
                        newLastCard!.alpha = 1.0
                        newLastCard!.frame = currentLastCardFrame
                    } else { //기존 카드들 이동
                        card.frame.size.width += self.widthDifference
                        card.frame.size.height += self.heightDifference
                        card.frame.origin.x -= (self.widthDifference + self.distance)
                        card.center.y = self.topCardViewSize.height / 2
                    }
                    card.layoutIfNeeded()
                    card.setNeedsLayout()
                }
            } completion: { finished in
                guard finished else {return}
                self.currentIndex += 1
                self.cardViews.removeFirst()
                currentFirstCard.removeFromSuperview()
                if self.currentIndex != self.numberOfCards {
                    self.delegate?.cardDidSwiped(currentTopCard: self.cardViews.first!)
                }
            }

        case .right:
            guard currentIndex > 0,
                  let currentLastCard = cardViews.last,
                  let currentFirstCardFrame = cardViews.first?.frame else {return}
            
            let newFirstCard = dataSource.card(at: currentIndex - 1)
            newFirstCard.alpha = 0
            newFirstCard.frame.size = topCardViewSize.applying(
                CGAffineTransform(
                    scaleX: 1.0 + differenceScale,
                    y: 1.0 + differenceScale)
            )
            newFirstCard.frame.origin.x = -currentFirstCardFrame.width
            newFirstCard.center.y = topCardViewSize.height / 2
            cardViews.insert(newFirstCard, at: 0)
            self.addSubview(newFirstCard)
            newFirstCard.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.3) {
                self.cardViews.enumerated().forEach { idx, card in
                    if card == currentLastCard && self.currentIndex + self.numberOfLayers <= self.numberOfCards { //제일 오른쪽 카드 사라짐
                        currentLastCard.frame.size = self.topCardViewSize.applying(
                            CGAffineTransform(
                                scaleX: 1.0 - (CGFloat(self.numberOfLayers) * self.differenceScale),
                                y: 1.0 - (CGFloat(self.numberOfLayers) * self.differenceScale)
                            )
                        )
                        currentLastCard.frame.origin.x += (self.widthDifference + self.distance)
                        currentLastCard.center.y = self.topCardViewSize.height / 2
                        currentLastCard.alpha = 0
                    } else if card == newFirstCard { //왼쪽에서 새로 들어올 카드 이동
                        card.alpha = 1.0 //왼쪽에 새롭게 추가된 카드 보이도록
                        card.frame = currentFirstCardFrame
                    } else { //기존 카드들 이동
                        card.frame.size.width -= self.widthDifference
                        card.frame.size.height -= self.heightDifference
                        card.frame.origin.x += (self.widthDifference + self.distance)
                        card.center.y = self.topCardViewSize.height / 2
                    }
                    card.layoutIfNeeded()
                    card.setNeedsLayout()
                }
                
            } completion: { finished in
                guard finished else {return}
                if self.currentIndex + self.numberOfLayers <= self.numberOfCards {
                    self.cardViews.removeLast()
                    currentLastCard.removeFromSuperview()
                }
                self.currentIndex -= 1
                self.delegate?.cardDidSwiped(currentTopCard: self.cardViews.first!)
            }

        default:
            break
        }
    }
    
}
