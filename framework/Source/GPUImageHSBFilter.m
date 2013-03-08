#import "GPUImageHSBFilter.h"

/* Matrix algorithms adapted from http://www.graficaobscura.com/matrix/index.html 
 
   Where rwgt is 0.3086, gwgt is 0.6094, and bwgt is 0.0820. This is the luminance vector. Notice here that we do not use the standard NTSC weights of 0.299, 0.587, and 0.114. The NTSC weights are only applicable to RGB colors in a gamma 2.2 color space. For linear RGB colors the values above are better.
 */
#define RLUM (0.3086f)
#define GLUM (0.6094f)
#define BLUM (0.0820f)

@implementation GPUImageHSBFilter

- (id)init
{
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (void)reset {
    identmat(matrix);
    [self _updateColorMatrix];
}

- (void)rotateHue:(float)h {
    huerotatemat(matrix, h);
    [self _updateColorMatrix];
}

- (void)adjustSaturation:(float)s {
    saturatemat(matrix, s);
    [self _updateColorMatrix];
}

- (void)adjustBrightness:(float)b {
    cscalemat(matrix, b, b, b);
    [self _updateColorMatrix];
}

- (void)_updateColorMatrix {
    GPUMatrix4x4 gpuMatrix;
    gpuMatrix.one.one = matrix[0][0];
    gpuMatrix.one.two = matrix[1][0];
    gpuMatrix.one.three = matrix[2][0];
    gpuMatrix.one.four = matrix[3][0];
    gpuMatrix.two.one = matrix[0][1];
    gpuMatrix.two.two = matrix[1][1];
    gpuMatrix.two.three = matrix[2][1];
    gpuMatrix.two.four = matrix[3][1];
    gpuMatrix.three.one = matrix[0][2];
    gpuMatrix.three.two = matrix[1][2];
    gpuMatrix.three.three = matrix[2][2];
    gpuMatrix.three.four = matrix[3][2];
    gpuMatrix.four.one = matrix[0][3];
    gpuMatrix.four.two = matrix[1][3];
    gpuMatrix.four.three = matrix[2][3];
    gpuMatrix.four.four = matrix[3][3];
    self.colorMatrix = gpuMatrix;
}

#pragma mark -

static void huerotatemat(CTMATRIX mat, float rot) {
	CTMATRIX mmat;
	float mag;
	float lx, ly, lz;
	float xrs, xrc;
	float yrs, yrc;
	float zrs, zrc;
	float zsx, zsy;
    
	identmat(mmat);
    
	/* rotate the grey vector into positive Z */
	mag = sqrt(2.0);
	xrs = 1.0 / mag;
	xrc = 1.0 / mag;
	xrotatemat(mmat, xrs, xrc);
	mag = sqrt(3.0);
	yrs = -1.0 / mag;
	yrc = sqrt(2.0) / mag;
	yrotatemat(mmat, yrs, yrc);
    
	/* shear the space to make the luminance plane horizontal */
	xformpnt(mmat, RLUM, GLUM, BLUM, &lx, &ly, &lz);
	zsx = lx / lz;
	zsy = ly / lz;
	zshearmat(mmat, zsx, zsy);
    
	/* rotate the hue */
	zrs = sin(rot * M_PI / 180.0);
	zrc = cos(rot * M_PI / 180.0);
	zrotatemat(mmat, zrs, zrc);
    
	/* unshear the space to put the luminance plane back */
	zshearmat(mmat, -zsx, -zsy);
    
	/* rotate the grey vector back into place */
	yrotatemat(mmat, -yrs, yrc);
	xrotatemat(mmat, -xrs, xrc);
    
	matrixmult(mmat, mat, mat);
}

/*
 *	saturatemat -
 *		make a saturation marix
 */
static void saturatemat(CTMATRIX mat, float sat) {
	CTMATRIX mmat;
	float a, b, c, d, e, f, g, h, i;
	float rwgt, gwgt, bwgt;
    
	rwgt = RLUM;
	gwgt = GLUM;
	bwgt = BLUM;
    
	a = (1.0f - sat) * rwgt + sat;
	b = (1.0f - sat) * rwgt;
	c = (1.0f - sat) * rwgt;
	d = (1.0f - sat) * gwgt;
	e = (1.0f - sat) * gwgt + sat;
	f = (1.0f - sat) * gwgt;
	g = (1.0f - sat) * bwgt;
	h = (1.0f - sat) * bwgt;
	i = (1.0f - sat) * bwgt + sat;
	mmat[0][0] = a;
	mmat[0][1] = b;
	mmat[0][2] = c;
	mmat[0][3] = 0.0f;
    
	mmat[1][0] = d;
	mmat[1][1] = e;
	mmat[1][2] = f;
	mmat[1][3] = 0.0f;
    
	mmat[2][0] = g;
	mmat[2][1] = h;
	mmat[2][2] = i;
	mmat[2][3] = 0.0f;
    
	mmat[3][0] = 0.0f;
	mmat[3][1] = 0.0f;
	mmat[3][2] = 0.0f;
	mmat[3][3] = 1.0f;
	matrixmult(mmat, mat, mat);
}

/*
 *	cscalemat -
 *		make a color scale matrix
 */
static void cscalemat(CTMATRIX mat, float rscale, float gscale, float bscale) {
	float mmat[4][4];
    
	mmat[0][0] = rscale;
	mmat[0][1] = 0.0f;
	mmat[0][2] = 0.0f;
	mmat[0][3] = 0.0f;
    
	mmat[1][0] = 0.0f;
	mmat[1][1] = gscale;
	mmat[1][2] = 0.0f;
	mmat[1][3] = 0.0f;
    
    
	mmat[2][0] = 0.0f;
	mmat[2][1] = 0.0f;
	mmat[2][2] = bscale;
	mmat[2][3] = 0.0f;
    
	mmat[3][0] = 0.0f;
	mmat[3][1] = 0.0f;
	mmat[3][2] = 0.0f;
	mmat[3][3] = 1.0f;
	matrixmult(mmat, mat, mat);
}

/*
 *	matrixmult -
 *		multiply two matricies
 */
static void matrixmult(CTMATRIX a, CTMATRIX b, CTMATRIX c) {
	int x, y;
	CTMATRIX temp;
    
	for (y = 0; y < 4; y++) {
		for (x = 0; x < 4; x++) {
			temp[y][x] = b[y][0] * a[0][x]
            + b[y][1] * a[1][x]
            + b[y][2] * a[2][x]
            + b[y][3] * a[3][x];
		}
	}
	for (y = 0; y < 4; y++) {
		for (x = 0; x < 4; x++) {
			c[y][x] = temp[y][x];
		}
	}
}

/*
 *	identmat -
 *		make an identity matrix
 */
static void identmat(CTMATRIX matrix) {
	memset(matrix, 0, sizeof(CTMATRIX));
	matrix[0][0] = 1.0f;
	matrix[1][1] = 1.0f;
	matrix[2][2] = 1.0f;
	matrix[3][3] = 1.0f;
}

/*
 *	xformpnt -
 *		transform a 3D point using a matrix
 */
static void xformpnt(CTMATRIX matrix, float x, float y, float z, float *tx, float *ty, float *tz) {
	*tx = x * matrix[0][0] + y * matrix[1][0] + z * matrix[2][0] + matrix[3][0];
	*ty = x * matrix[0][1] + y * matrix[1][1] + z * matrix[2][1] + matrix[3][1];
	*tz = x * matrix[0][2] + y * matrix[1][2] + z * matrix[2][2] + matrix[3][2];
}

/*
 *	offsetmat -
 *		offset r, g, and b
 */
static void offsetmat(CTMATRIX mat, float roffset, float goffset, float boffset) {
	CTMATRIX mmat;
    
	mmat[0][0] = 1.0f;
	mmat[0][1] = 0.0f;
	mmat[0][2] = 0.0f;
	mmat[0][3] = 0.0f;
    
	mmat[1][0] = 0.0f;
	mmat[1][1] = 1.0f;
	mmat[1][2] = 0.0f;
	mmat[1][3] = 0.0f;
    
	mmat[2][0] = 0.0f;
	mmat[2][1] = 0.0f;
	mmat[2][2] = 1.0f;
	mmat[2][3] = 0.0f;
    
	mmat[3][0] = roffset;
	mmat[3][1] = goffset;
	mmat[3][2] = boffset;
	mmat[3][3] = 1.0f;
	matrixmult(mmat, mat, mat);
}

/*
 *	xrotate -
 *		rotate about the x (red) axis
 */
static void xrotatemat(CTMATRIX mat, float rs, float rc) {
	CTMATRIX mmat;
    
	mmat[0][0] = 1.0f;
	mmat[0][1] = 0.0f;
	mmat[0][2] = 0.0f;
	mmat[0][3] = 0.0f;
    
	mmat[1][0] = 0.0f;
	mmat[1][1] = rc;
	mmat[1][2] = rs;
	mmat[1][3] = 0.0f;
    
	mmat[2][0] = 0.0f;
	mmat[2][1] = -rs;
	mmat[2][2] = rc;
	mmat[2][3] = 0.0f;
    
	mmat[3][0] = 0.0f;
	mmat[3][1] = 0.0f;
	mmat[3][2] = 0.0f;
	mmat[3][3] = 1.0f;
	matrixmult(mmat, mat, mat);
}

/*
 *	yrotate -
 *		rotate about the y (green) axis
 */
static void yrotatemat(CTMATRIX mat, float rs, float rc) {
	CTMATRIX mmat;
    
	mmat[0][0] = rc;
	mmat[0][1] = 0.0f;
	mmat[0][2] = -rs;
	mmat[0][3] = 0.0f;
    
	mmat[1][0] = 0.0f;
	mmat[1][1] = 1.0f;
	mmat[1][2] = 0.0f;
	mmat[1][3] = 0.0f;
    
	mmat[2][0] = rs;
	mmat[2][1] = 0.0f;
	mmat[2][2] = rc;
	mmat[2][3] = 0.0f;
    
	mmat[3][0] = 0.0f;
	mmat[3][1] = 0.0f;
	mmat[3][2] = 0.0f;
	mmat[3][3] = 1.0f;
	matrixmult(mmat, mat, mat);
}

/*
 *	zrotate -
 *		rotate about the z (blue) axis
 */
static void zrotatemat(CTMATRIX mat, float rs, float rc) {
	CTMATRIX mmat;
    
	mmat[0][0] = rc;
	mmat[0][1] = rs;
	mmat[0][2] = 0.0f;
	mmat[0][3] = 0.0f;
    
	mmat[1][0] = -rs;
	mmat[1][1] = rc;
	mmat[1][2] = 0.0f;
	mmat[1][3] = 0.0f;
    
	mmat[2][0] = 0.0f;
	mmat[2][1] = 0.0f;
	mmat[2][2] = 1.0f;
	mmat[2][3] = 0.0f;
    
	mmat[3][0] = 0.0f;
	mmat[3][1] = 0.0f;
	mmat[3][2] = 0.0f;
	mmat[3][3] = 1.0f;
	matrixmult(mmat, mat, mat);
}

/*
 *	zshear -
 *		shear z using x and y.
 */
static void zshearmat(CTMATRIX mat, float dx, float dy) {
	CTMATRIX mmat;
    
	mmat[0][0] = 1.0f;
	mmat[0][1] = 0.0f;
	mmat[0][2] = dx;
	mmat[0][3] = 0.0f;
    
	mmat[1][0] = 0.0f;
	mmat[1][1] = 1.0f;
	mmat[1][2] = dy;
	mmat[1][3] = 0.0f;
    
	mmat[2][0] = 0.0f;
	mmat[2][1] = 0.0f;
	mmat[2][2] = 1.0f;
	mmat[2][3] = 0.0f;
    
	mmat[3][0] = 0.0f;
	mmat[3][1] = 0.0f;
	mmat[3][2] = 0.0f;
	mmat[3][3] = 1.0f;
	matrixmult(mmat, mat, mat);
}

@end
