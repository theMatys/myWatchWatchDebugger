//
//  WDImageView.swift
//  myWatch
//
//  Created by Máté on 2017. 05. 23..
//  Copyright © 2017. theMatys. All rights reserved.
//

import Cocoa

@IBDesignable
class WDImageView: NSImageView
{
    @IBInspectable var tintingColor: NSColor = NSColor.black
    {
        didSet
        {
            if(!silent)
            {
                self.silently().image = tintedImage()
            }
            else
            {
                silent = false
            }
        }
    }
    
    @IBInspectable var gradientTinted: Bool = false
    {
        didSet
        {
            if(!silent)
            {
                self.silently().image = tintedImage()
            }
            else
            {
                silent = false
            }
        }
    }
    
    @IBInspectable var tintingGradient: WDGradient = WDDefaults.Gradients.defaultGradient
    {
        didSet
        {
            if(!silent)
            {
                self.silently().image = tintedImage()
            }
            else
            {
                silent = false
            }
        }
    }
    
    override var image: NSImage?
    {
        didSet
        {
            if(!silent)
            {
                self.silently().image = tintedImage()
            }
            else
            {
                silent = false
            }
        }
    }
    
    private var silent = false
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.image = tintedImage()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        self.image = tintedImage()
    }
    
    func silently() -> WDImageView
    {
        silent = true
        return self
    }
    
    private func tintedImage() -> NSImage?
    {
        if(self.gradientTinted)
        {
            return self.image?.tinted(with: self.tintingGradient)
        }
        else
        {
            return self.image?.tinted(with: self.tintingColor)
        }
    }
}
