//
//  CrookedText.swift
//
//  The MIT License (MIT)
//  Copyright (c) 2019 Tobias Due Munk
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import SwiftUI

public struct CrookedText: View {
    
    public enum Position {
        case inside, center, outside
    }
    public enum Direction {
        case clockwise, counterclockwise
    }
    
    public let text: String
    public let radius: CGFloat
    public let alignment: Position
    public let direction: Direction
    
    internal var textModifier: (Text) -> Text
    internal var spacing: CGFloat = 0
    internal var advance: CGFloat = 0
    
    @State private var sizes: [CGSize] = []
    
    public init(text: String,
                radius: CGFloat,
                alignment: Position = .center,
                direction: Direction = .clockwise,
                textModifier: @escaping (Text) -> Text = { $0 }) {
        self.text = text
        self.radius = radius
        self.alignment = alignment
        self.direction = direction
        self.textModifier = textModifier
    }
    
    private func textRadius(at index: Int) -> CGFloat {
        switch alignment {
        case .inside:
            return radius - size(at: index).height / 2
        case .center:
            return radius
        case .outside:
            return radius + size(at: index).height / 2
        }
    }
    
    public var body: some View {
        VStack {
            ZStack {
                ForEach(textAsCharacters()) { item in
                    PropagateSize {
                        self.textView(char: item)
                            .scaleEffect(scaleSize())
                    }
                    .frame(width: self.size(at: index(item.index)).width,
                           height: self.size(at: index(item.index)).height)
                    .offset(x: 0,
                            y: -self.textRadius(at: index(item.index)))
                    .rotationEffect(self.angle(at: index(item.index)))
               }
            }
            .frame(width: radius * 2, height: radius * 2)
            .onPreferenceChange(TextViewSizeKey.self) { sizes in
                self.sizes = sizes
            }
        }
        .accessibility(label: Text(text))
    }
    
    private func scaleSize() -> CGSize {
        switch self.direction {
        case .clockwise: CGSize(width: 1, height: 1)
        case .counterclockwise: CGSize(width: -1, height: -1)
        }
    }
    
    private func transformEffect() -> CGAffineTransform {
        switch self.direction {
        case .clockwise: CGAffineTransform()
        case .counterclockwise: CGAffineTransform(scaleX: -1, y: -1)
        }
    }
    
    private func index(_ index: Int) -> Int {
        switch self.direction {
        case .clockwise: index
        case .counterclockwise: text.count - index - 1
        }
    }

    private func textAsCharacters() -> [IdentifiableCharacter] {
        if (self.direction == .clockwise) {
            text.enumerated().map(IdentifiableCharacter.init)
        } else {
            text.enumerated().reversed().map(IdentifiableCharacter.init)
        }
    }

    private func textView(char: IdentifiableCharacter) -> some View {
        textModifier(Text(char.string))
    }

    private func size(at index: Int) -> CGSize {
        sizes[safe: index] ?? CGSize(width: 1000000, height: 0)
    }

    private func angle(at index: Int) -> Angle {
        let arcSpacing = Double(spacing / radius)
        let letterWidths = sizes.map { $0.width }
        let prevWidth =
            index < letterWidths.count ?
            letterWidths.dropLast(letterWidths.count - index).reduce(0, +) :
            0
        let prevArcWidth = Double(prevWidth / radius)
        let totalArcWidth = Double(letterWidths.reduce(0, +) / radius)
        let prevArcSpacingWidth = arcSpacing * Double(index)
        let arcSpacingOffset = -arcSpacing * Double(letterWidths.count - 1) / 2
        let charWidth = letterWidths[safe: index] ?? 0
        let charOffset = Double(charWidth / 2 / radius)
        let arcCharCenteringOffset = -totalArcWidth / 2
        let charArcOffset = prevArcWidth + charOffset + arcCharCenteringOffset + arcSpacingOffset + prevArcSpacingWidth
        return Angle(radians: charArcOffset + self.advance)
    }
}

#Preview {
    VStack {
        ZStack {
            Circle().fill(Color.yellow).frame(width: 150, height: 150)
            CrookedText(text: "Clockwize", radius: 75, alignment: .inside)
        }
        ZStack {
            Circle().fill(Color.yellow).frame(width: 150, height: 150)
            CrookedText(text: "Counter Clockwise", radius: 75, alignment: .inside, direction: .counterclockwise)
                .advance(radians: .pi)
        }
        ZStack {
            Circle().fill(Color.yellow).frame(width: 100, height: 100)
            CrookedText(text: "advanced", radius: 50)
                .advance(radians: 3.14159)
        }
    }
}
