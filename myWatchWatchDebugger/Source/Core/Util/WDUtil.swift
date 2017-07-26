//
//  WDUtil.swift
//  myWatchWatchDebugger
//
//  Created by Máté on 2017. 07. 22..
//  Copyright © 2017. theMatys. All rights reserved.
//

import Cocoa

infix operator ?! : NilCoalescingPrecedence
infix operator ?= : NilCoalescingPrecedence
infix operator ??! : NilCoalescingPrecedence
infix operator ??= : NilCoalescingPrecedence
infix operator >< : ComparisonPrecedence

infix operator -- : AdditionPrecedence

func ?!(left: Any?, right: () -> Swift.Void)
{
    if(left != nil)
    {
        right()
    }
}

func ?=(left: Any?, right: () -> Swift.Void)
{
    if(left == nil)
    {
        right()
    }
}

func ??!(left: Any?, right: () -> Swift.Void) -> NilcheckResult
{
    if(left != nil)
    {
        right()
        return NilcheckResult(result: true)
    }
    else
    {
        return NilcheckResult(result: false)
    }
}

func ??=(left: Any?, right: () -> Swift.Void) -> NilcheckResult
{
    if(left == nil)
    {
        right()
        return NilcheckResult(result: true)
    }
    else
    {
        return NilcheckResult(result: false)
    }
}

func ><(left: NilcheckResult, right: () -> Swift.Void)
{
    if(!left)
    {
        right()
    }
}


func --(left: CGFloat, right: CGFloat) -> CGFloat
{
    return left - (left - right)
}

func +<ObjectType>(left: Array<ObjectType>, right: ObjectType) -> [ObjectType]
{
    var copy: [ObjectType] = left
    copy.append(right)
    return copy
}

func -<ObjectType>(left: Array<ObjectType>, right: Int) -> [ObjectType]
{
    var copy: [ObjectType] = left
    copy.remove(at: right)
    return copy
}

func -<ObjectType: Equatable>(left: Array<ObjectType>, right: ObjectType) -> [ObjectType]
{
    var copy: [ObjectType] = left
    
    if(copy.contains(right))
    {
        copy.remove(at: copy.index(of: right)!)
    }
    
    return copy
}

class NilcheckResult
{
    var result: Bool = false
    
    private init() {}
    
    fileprivate init(result: Bool)
    {
        self.result = result
    }
    
    static prefix func !(right: NilcheckResult) -> Bool
    {
        return !right.result
    }
}

class WDUtil
{
    //MARK: Static functions
    
    /// Downcasts an object into the specified type.
    ///
    /// - Parameters:
    ///   - to: The parameter, with the specific type, that the new value should be written into.
    ///   - from: The parameter we should downcast from.
    static func downcast<ObjectType>(to: inout ObjectType, from: Any)
    {
        //Check if downcast is possible
        if(from is ObjectType)
        {
            //If yes, downcast
            to = from as! ObjectType
        }
        else
        {
            //If no, throw a fatal error
            fatalError("Could not downcast because the object: \(type(of: from)) is not an instance of: \(ObjectType.self)")
        }
    }
    
    /// Downcasts an object into the specified type and returns the result.
    ///
    /// - Parameters:
    ///   - from: The parameter we should downcast from.
    static func downcastReturn<ObjectType>(from: Any) -> ObjectType
    {
        //Declare the return value
        var ret: ObjectType!
        
        //Downcast into the return value
        downcast(to: &ret, from: from)
        
        //Return the new object
        return ret
    }
}

//MARK: -

/// Our own gradient implementation.
class WDGradient
{
    //MARK: Instance variables
    
    /// Holds the colors of this gradient.
    var colors: [NSColor]
    
    /// Holds the colors of this gradient as `CGColor` references.
    var cgColors: [CGColor]
    
    /// Holds the stops where the corresponding colors should be placed.
    var points: [CGFloat]
    
    //MARK: - Initializers
    
    /// Makes an `MWGradient` instance out of the given parameters.
    ///
    /// - Parameters:
    ///   - colors: The colors the gradient should use.
    ///   - points: The points within the gradient where the colors should be placed.
    init(colors: NSColor..., points: [CGFloat]? = nil)
    {
        //Store the parameters
        self.colors = colors
        self.points = [CGFloat]()
        
        self.cgColors = [CGColor]()
        
        //Convert the UIColors into CGColors
        self.colors.forEach { (color: NSColor) in
            cgColors.append(color.cgColor)
        }
        
        //Spread the points if we have more than two colors
        if(colors.count > 2)
        {
            points ??= {
                let spread: CGFloat = CGFloat(1 / colors.count)
                
                for i in 0..<self.colors.count
                {
                    self.points.append(spread * CGFloat(i + 1))
                }
            } >< {
                self.points = points!
            }
        }
        else
        {
            //If we only have two, distribute from start to end
            self.points = [0.0, 1.0]
        }
    }
    
    //MARK: Instance functions
    
    /// Converts the `MWGradient` instance into `CGGradient`.
    ///
    /// - Returns: The `CGGradient` constructed from this gradient.
    func cgGradient() -> CGGradient
    {
        //Create the color space
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        //Make the return value
        let ret: CGGradient = CGGradient(colorsSpace: colorSpace, colors: cgColors as CFArray, locations: points)!
        
        //Return the gradient
        return ret
    }
}

//MARK: -

/// A small class which acts like a "queue" collection.
///
/// Works similarly to a stack, but exactly inversed.
///
/// When we push, as in a stack, we push to the end of the array.
///
/// However when we pop, we do not pop the last item of the array, but the first.
class WDQueue<Type>
{
    //MARK: Instance variables
    
    /// The array which holds the queued items.
    ///
    /// Initialized as an empty array or can be given an inital value in `init(with:)`
    private var queue: [Type]
    
    /// The number of items in the queue.
    ///
    /// Updated whenever we remove or add an item to the queue.
    var count: Int
    
    //MARK: - Initializers
    
    /// Initializer which creates an empty queue.
    ///
    /// - Returns: An initialized `MWQueue` instance.
    init()
    {
        self.queue = [Type]()
        self.count = 0
    }
    
    /// Initializer which creates a queue with the specified items.
    ///
    /// The queue order will be as the order of items in list `items`
    ///
    /// - Parameter items: The items that will be copied over to the queue.
    ///
    /// - Returns: An initialized `MWQueue` instance.
    init(with items: Type...)
    {
        self.queue = items
        self.count = queue.count
    }
    
    /// Initializer which creates a queue with the specified array of items.
    ///
    /// The queue order will be as the order of items in array `items`
    ///
    /// - Parameter items: The items that will be copied over to the queue.
    ///
    /// - Returns: An initialized `MWQueue` instance.
    init(with items: [Type])
    {
        self.queue = items
        self.count = queue.count
    }
    
    //MARK: Instance functions
    
    /// Function which adds (pushes) an item to the end of the queue.
    ///
    /// - Parameter item: The item that will be added to the end of the queue.
    func push(_ item: Type)
    {
        queue.append(item)
        count += 1
    }
    
    /// Function which returns the first item from the queue without removing it from the queue.
    ///
    /// - Returns: The upcoming (first) item in the queue.
    func peek() -> Type
    {
        return queue[0]
    }
    
    /// Function which removes the upcoming (first) item from the queue.
    func pop()
    {
        queue.remove(at: 0)
        count -= 1
    }
    
    /// Function which removes the upcoming (first) item from the queue and than returns it.
    ///
    /// - Returns: The popped (upcoming/first) item of the queue (which is no longer in the queue).
    func pop_ret() -> Type
    {
        let ret = queue[0]
        queue.remove(at: 0)
        
        count -= 1
        
        return ret
    }
    
    /// Function which removes an item at the specified location.
    func pop(at: Int)
    {
        queue.remove(at: at)
        count -= 1
    }
    
    /// Function which removes an item at the specified location and than returns it.
    ///
    /// - Returns: The popped item of the queue (which is no longer in the queue).
    func pop_ret(at: Int) -> Type
    {
        let ret = queue[at]
        queue.remove(at: at)
        
        count -= 1
        
        return ret
    }
}
