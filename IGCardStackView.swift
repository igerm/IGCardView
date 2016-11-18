//
//  IGCardStackView.swift
//
//  Created by Germán Azcona on 10/13/16.
//  Copyright © 2016 Top Waiter Inc. All rights reserved.
//

import Foundation
import UIKit

@objc
protocol IGCardStackViewDelegate {
    
    func numberOfCardsForCardStackView(cardStackView:TWCardStackView) -> Int
    func cardStackView(cardStackView:TWCardStackView, cardForIndex:Int) -> TWCardView
    optional func cardStackView(cardStackView:TWCardStackView, scrolledToIndex:Int) -> Void
}

class IGCardView: UIView {
    
}

class IGCardStackView: UIView, UIScrollViewDelegate {
    
    @IBOutlet weak var delegate: TWCardStackViewDelegate? {
        didSet {
            self.reloadCards()
        }
    }
    
    lazy var scrollView:UIScrollView = {
        [unowned self] in
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.frame = self.bounds
        scrollView.pagingEnabled = true
        scrollView.contentSize = self.frame.size
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        self.addSubview(scrollView)
        return scrollView
    }()
    
    var hasNextCard:Bool {
        if self.currentCardIndex < cardCounts-1 {
            return true
        }
        return false
    }
    var hasPreviousCard:Bool {
        if self.currentCardIndex > 0 {
            return true
        }
        return false
    }
    
    var currentCardIndex:Int {
        return Int(round((scrollView.contentOffset.x)/scrollView.frame.size.width))
    }
    func scrollToCardIndex(index:Int, animated:Bool) {
        self.scrollView.setContentOffset(CGPoint(x: CGFloat(index)*scrollView.frame.size.width, y:0), animated: animated)
    }
    
    override func layoutSubviews() {
        
        self.cardSize = CGSizeMake(max(self.frame.size.width-60,1),
                                   max(self.frame.size.height-70,1))
        
        let index = self.currentCardIndex
        
        
        reloadContentSize()
        repositionAllCards()
        
        var frame = self.frame
        frame.origin = CGPointZero
        self.scrollView.frame = frame
        
        repositionAllCards()
        
        self.scrollToCardIndex(index, animated: false)
    }
    
    var cardsLoaded = false
    var cardCounts:Int = 0
    
    var cardViews = [Int:TWCardView]()
    
    func reloadCards() {
        
        cardsLoaded = true
        
        for view in cardViews.values {
            view.removeFromSuperview()
        }
        cardViews.removeAll()
        
        cardCounts = delegate?.numberOfCardsForCardStackView(self) ?? 0
        
        for i in 0..<cardCounts {
            let cardView = cardForIndex(i)
            self.scrollView.insertSubview(cardView, atIndex: 0)
            positionCardView(cardView, atIndex:i)
        }
        
        reloadContentSize()
    }
    
    func reloadContentSize() {
        
        var contentSize = self.frame.size
        contentSize.width *= CGFloat(cardCounts)
        self.scrollView.contentSize = contentSize
        
    }
    
    func cardForIndex(index:Int) -> TWCardView {
        
        var cardView:TWCardView? = cardViews[index]
        
        if cardView == nil {
            cardView = delegate!.cardStackView(self, cardForIndex:index)
            cardViews[index] = cardView
        }
        
        return cardView!
    }
    
    var cardSize:CGSize = CGSizeMake(100, 100)
    
    var cardYOffset:CGFloat = -15
    
    func positionCardView(cardView:TWCardView, atIndex index:Int) {
        
        let contentOffsetX = self.scrollView.contentOffset.x
        
        let selfWidth = self.frame.size.width
        let selfHeight = self.frame.size.height
        
        let currentCardIndex = floor(contentOffsetX / selfWidth) //current card is the card that is transitioning (not necesarily the cardView that we have to position)
        
        let indexFloat = CGFloat(index)
        
        cardView.transform = CGAffineTransformIdentity
        var frame = CGRectZero
        frame.size = cardSize
        cardView.frame = frame
        
        var scale:CGFloat = 1
        var center:CGPoint = CGPointZero
        
        if indexFloat == currentCardIndex {
            //it's transition from the center to the left
            let progress = (contentOffsetX / selfWidth) - currentCardIndex //goes from 0 to 1
            let xOffset = selfWidth * progress
            center = CGPoint(x: (selfWidth/2.0)-xOffset, y: selfHeight/2.0+cardYOffset)
        }
        else if indexFloat < currentCardIndex {
            //get it out of sight
            center = CGPoint(x: -(selfWidth/2.0), y: selfHeight/2.0+cardYOffset)
        }
        else if indexFloat > currentCardIndex {
            //it's in the stack, center add Y offset and transform to reduce size
            let ratio = (indexFloat*selfWidth-contentOffsetX)/(self.scrollView.contentSize.width-selfWidth) //1...0
            
            if index == 2 {
                print(String(format: "contentOffsetX:%2.2f ratio:%2.2f",contentOffsetX, ratio ))
            }
            scale = 0.7+0.3*(1-ratio) //apply scale to the 30% of the size
            
            let range:CGFloat =  self.frame.size.height/2 - (self.frame.size.height-cardSize.height*0.7)
            
            let yOffset:CGFloat = ratio*range*1.9
            
            center = CGPoint(x: (selfWidth/2.0), y: selfHeight/2.0+yOffset+cardYOffset)
            
        }
        
        center.x += contentOffsetX
        
        cardView.center = center
        
        //print("frame \(index): x\(cardView.frame.origin.x), y\(cardView.frame.origin.y), w\(cardView.frame.size.width), h\(cardView.frame.size.height)  scale\(scale)")
        cardView.transform = CGAffineTransformMakeScale(scale, scale)
    }
    
    //MARK: - ScrollView
    
    func scrollViewDidScroll(scrollView:UIScrollView) {
        
        repositionAllCards()
        
        let currentCardIndex = min(cardCounts-1,max(0,Int(floor(self.scrollView.contentOffset.x / self.frame.size.width))))
        delegate?.cardStackView?(self, scrolledToIndex: currentCardIndex)
    }
    
    //recalculate cards position and transformation
    func repositionAllCards() {
        
        for i in 0..<cardCounts {
            
            let cardView = cardForIndex(i)
            
            positionCardView(cardView, atIndex:i)
        }
    }
    
    
}
