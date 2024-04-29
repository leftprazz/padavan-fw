// This file Copyright © 2007-2023 Transmission authors and contributors.
// It may be used under the MIT (SPDX: MIT) license.
// License text can be found in the licenses/ folder.

#import <AppKit/AppKit.h>

@interface DragOverlayView : NSView

- (void)setOverlay:(NSImage*)icon mainLine:(NSString*)mainLine subLine:(NSString*)subLine;

@end
