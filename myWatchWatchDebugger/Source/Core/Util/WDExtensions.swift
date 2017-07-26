//
//  WDExtensions.swift
//  myWatchWatchDebugger
//
//  Created by Máté on 2017. 07. 23..
//  Copyright © 2017. theMatys. All rights reserved.
//

import Cocoa

//MARK: -
extension NSColor
{
    /// Used to retrieve the red component from this `NSColor`.
    ///
    /// - Returns: The red component of this `NSColor`
    func getComponentRed() -> CGFloat
    {
        return self.cgColor.components![0]
    }
    
    /// Used to retrieve the green component from this `NSColor`.
    ///
    /// - Returns: The green component of this `NSColor`
    func getComponentGreen() -> CGFloat
    {
        return self.cgColor.components![1]
    }
    
    /// Used to retrieve the blue component from this `NSColor`.
    ///
    /// - Returns: The blue component of this `NSColor`
    func getComponentBlue() -> CGFloat
    {
        return self.cgColor.components![2]
    }
    
    /// Used to retrieve the alpha component from this `NSColor`.
    ///
    /// - Returns: The alpha component of this `NSColor`
    func getComponentAlpha() -> CGFloat
    {
        return self.cgColor.components![3]
    }
    
    /// Returns this `NSColor`, but with `amount` added to each component (except the alpha).
    ///
    /// - Parameter amount: The scalar that should be added to each component.
    /// - Returns: A new `UIColor` with `amount` added to each of its components (except the alpha).
    func adding(_ amount: CGFloat) -> NSColor
    {
        return NSColor(red: self.getComponentRed() + amount, green: self.getComponentGreen() + amount, blue: self.getComponentBlue() + amount, alpha: self.getComponentAlpha())
    }
    
    /// Returns this `NSColor`, but with `amount` substracted from each component (except the alpha).
    ///
    /// - Parameter amount: The scalar that should be substracted from each component.
    /// - Returns: A new `UIColor` with `amount` substracted from each of its components (except the alpha).
    func substracting(_ amount: CGFloat) -> NSColor
    {
        return NSColor(red: self.getComponentRed() - amount, green: self.getComponentGreen() - amount, blue: self.getComponentBlue() - amount, alpha: self.getComponentAlpha())
    }
    
    /// Returns this `NSColor`, but with `amount` multiplied by each component (except the alpha).
    ///
    /// - Parameter amount: The scalar that should be multiplied by each component.
    /// - Returns: A new `UIColor` with `amount` multiplied by each of its components (except the alpha).
    func multiplying(_ amount: CGFloat) -> NSColor
    {
        return NSColor(red: self.getComponentRed() * amount, green: self.getComponentGreen() * amount, blue: self.getComponentBlue() * amount, alpha: self.getComponentAlpha())
    }
}

//MARK: -
extension NSImage
{
    var _cgImage: CGImage!
    {
        get
        {
            var rect: NSRect = NSRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height)
            return self.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        }
    }
    
    
    /// Tints the image with a single color.
    ///
    /// - Parameter color: The color the image should be tinted with.
    /// - Returns: The tinted image.
    func tinted(with color: NSColor) -> NSImage?
    {
        //Declare a default return value
        var ret: NSImage?
        
        //Check if the image can be used
        _cgImage ?! {
            //Create the graphics context for the image
            self.lockFocus()
            
            //Create the context
            let context: CGContext! = NSGraphicsContext.current()?.cgContext
            
            context ?! {
                //Create a rectandle which is capable of holding the new image
                let rect: CGRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
                
                //Make the new image
                context.translateBy(x: 0, y: self.size.height)
                context.scaleBy(x: 1.0, y: -1.0)
                context.setBlendMode(.normal)
                context.clip(to: rect, mask: self._cgImage)
                color.setFill()
                context.fill(rect)
                
                //Get the new image and end the context
                let newImage: CGImage? = context.makeImage()
                ret = newImage != nil ? NSImage(cgImage: newImage!, size: NSSize(width: newImage!.width, height: newImage!.height)) : nil
            }
            
            //Release the image's drawing context
            self.unlockFocus()
        }
        
        return ret
    }
    
    /// Tints the image with a gradient.
    ///
    /// - Parameter gradient: The gradient the image should be tinted with.
    /// - Returns: The tinted image.
    func tinted(with gradient: WDGradient) -> NSImage?
    {
        //Declare a default return value
        var ret: NSImage?
        
        //Check if the image can be used
        _cgImage ?! {
            //Create the graphics context for the image
            self.lockFocus()
            
            //Create the context
            let context: CGContext! = NSGraphicsContext.current()?.cgContext
            
            context ?! {
                //Create a rectandle which is capable of holding the new image
                let rect: CGRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
                
                //Make the new image
                context.translateBy(x: 0, y: self.size.height)
                context.scaleBy(x: 1.0, y: -1.0)
                context.setBlendMode(.normal)
                context.clip(to: rect, mask: self._cgImage)
                context.drawLinearGradient(gradient.cgGradient(), start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0, y: rect.height), options: CGGradientDrawingOptions(rawValue: 0))
                
                //Get the new image and end the context
                let newImage: CGImage? = context.makeImage()
                ret = newImage != nil ? NSImage(cgImage: newImage!, size: NSSize(width: newImage!.width, height: newImage!.height)) : nil
            }
            
            //Release the image's drawing context
            self.unlockFocus()
        }
        
        return ret
    }
}
