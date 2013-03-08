#import "GPUImageColorMatrixFilter.h"

typedef float CTMATRIX[4][4];

@interface GPUImageHSBFilter : GPUImageColorMatrixFilter {
    CTMATRIX matrix;
}

- (void)reset;
- (void)rotateHue:(float)h;
- (void)adjustSaturation:(float)s;
- (void)adjustBrightness:(float)b;

@end
