//
//  XGFrameReader.m
//  xGrab
//
//  Created by Filipe Varela on 07/12/18.
//  Copyright 2007 Filipe Varela. All rights reserved.
//

#import <OpenGL/CGLMacro.h>
#import "XGFrameReader.h"

@interface XGFrameReader (PrivateMethods)
- (void)readScreenAsynchSynchronized:(id)param;
- (void)flipBuffer;
@end

@implementation XGFrameReader (PrivateMethods)
- (void)readScreenAsynchSynchronized:(id)param
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @synchronized([XGFrameReader class])
    {
        mRecordTime = [NSDate timeIntervalSinceReferenceDate];
        mRecordTime = mRecordTime - mStartTime;
        
        BOOL success = [self readScreenAsynchBegin];
        if (success)
            [mQueueController addItemToFilledQueue:self];
    }
    
    [pool release];
}

- (void)flipBuffer
{
    unsigned i;
    unsigned char *src, *dst, temp[(mWidth * 4 + 63) & ~63];
    
    for (i = 0; i < mHeight/2; ++i) {
        src = mBaseAddress + mBufferRowBytes * i;
        dst = mBaseAddress + mBufferRowBytes * (mHeight - 1 - i);
        bcopy(dst, temp, mWidth * 4);
        bcopy(src, dst, mWidth * 4);
        bcopy(temp, src, mWidth * 4);
    }
}

@end

@implementation XGFrameReader

- (id)initWithOpenGLContext:(NSOpenGLContext *)context pixelsWide:(unsigned)width pixelsHigh:(unsigned)height queueController:(XGQueueController *)controller
{
    CGLContextObj cgl_ctx = [context CGLContextObj];
    GLint save1,save2,save3,save4;
    CVReturn theError;
    NSMutableDictionary *attributes;
    
    if ((context == nil) || ((width == 0) || (height == 0))) {
        [self release];
        return nil;
    }
    
    if ((self = [super init])) {
        CGLLockContext(cgl_ctx);
        mQueueController = [controller retain];
        mGLContext = [context retain];
        mWidth = width;
        mHeight = height;
        
        attributes = [NSMutableDictionary dictionary];
        #if __BIG_ENDIAN__
            [attributes setObject:[NSNumber numberWithUnsignedInt:k32ARGBPixelFormat] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        #else
            [attributes setObject:[NSNumber numberWithUnsignedInt:k32BGRAPixelFormat] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        #endif
		[attributes setObject:[NSNumber numberWithUnsignedInt:width] forKey:(NSString*)kCVPixelBufferWidthKey];
		[attributes setObject:[NSNumber numberWithUnsignedInt:height] forKey:(NSString*)kCVPixelBufferHeightKey];
		
        theError = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (CFDictionaryRef)attributes, &mBufferPool);
		if(theError != kCVReturnSuccess) 
		{
			NSLog(@"CVPixelBufferPoolCreate(): %i", theError);
			[self release];
			return nil;
		}
        
		theError = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, mBufferPool, &mPixelBuffer);
		if(theError) {
			NSLog(@"CVPixelBufferPoolCreatePixelBuffer(): %i", theError);
			return NULL;
		}
		
		theError = CVPixelBufferLockBaseAddress(mPixelBuffer, (GLint)0);
		if(theError) {
			NSLog(@"CVPixelBufferLockBaseAddress(): %i", theError);
			return NULL;
		}
        
		mBaseAddress = CVPixelBufferGetBaseAddress(mPixelBuffer);
		mBufferRowBytes = CVPixelBufferGetBytesPerRow(mPixelBuffer);
        glGenTextures(1, &mTextureName);
		glGetIntegerv(GL_TEXTURE_BINDING_RECTANGLE_EXT, &save1);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, mTextureName);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
		glGetIntegerv(GL_UNPACK_ALIGNMENT, &save2);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
		glGetIntegerv(GL_UNPACK_ROW_LENGTH, &save3);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, mBufferRowBytes / 4);
		glGetIntegerv(GL_UNPACK_CLIENT_STORAGE_APPLE, &save4);
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
		glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, mWidth, mHeight, 0, GL_BGRA,GL_UNSIGNED_INT_8_8_8_8_REV, mBaseAddress);
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, save4);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, save3);
		glPixelStorei(GL_UNPACK_ALIGNMENT, save2);
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, save1);
        
		theError = glGetError();
		if(theError) {
			NSLog(@"Create textures: 0x%04X", theError);
			[self release];
			CGLUnlockContext(cgl_ctx);
			return nil;
		}
		CGLUnlockContext(cgl_ctx);
	}
    
    // register for movie finish so we can clear our ref to frameQueueController
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(clearQueueController) name:@"sharedMovieSaved" object: nil];
    
	return self;
}

// notification from queuecontroller saying it's ok to clear our ref (he is finished)
- (void)clearQueueController
{
    [mQueueController release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) dealloc
{
    CGLContextObj cgl_ctx = [mGLContext CGLContextObj];
	
	if(mBufferPool)
		CVPixelBufferPoolRelease(mBufferPool);
    
	if (mPixelBuffer)
		CVPixelBufferRelease(mPixelBuffer);
	
	if(mTextureName)
		glDeleteTextures(1, &mTextureName);
    
	//Release context
	[mGLContext release];
	
	[super dealloc];
    #ifdef __DEBUG_TARGET__
        NSLog(@"XGFrameReader Dealloc");
    #endif
}

- (void)readScreenAsynchOnSeparateThread
{
    [NSThread detachNewThreadSelector:@selector(readScreenAsynchSynchronized:) toTarget:self withObject:(id)nil];
}

- (BOOL)readScreenAsynchBegin
{
	CGLContextObj cgl_ctx = [mGLContext CGLContextObj]; CGLLockContext(cgl_ctx);
	GLenum theError = GL_NO_ERROR;
	BOOL success = YES;
	GLint save1;
    CGError myErr;
    
    // save cursor position for this frame
    cursorPosition = [NSEvent mouseLocation];
    CGSConnectionRef conn = _CGSDefaultConnection();
    myErr = CGSGetGlobalCursorDataSize(conn,&cursorDataSize);
    myErr = CGSGetGlobalCursorData(conn,cursorImageBuffer,&cursorDataSize,&cursorPlanes,&cursorRect,&cursorHotSpot,&cursorDepth,&cursorComponents,&cursorBitsPerComponent);
    cursorPosition.x -= cursorHotSpot.x;
    cursorPosition.y += cursorHotSpot.y;
    
    glGetIntegerv(GL_TEXTURE_BINDING_RECTANGLE_EXT, &save1);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, mTextureName);
	glCopyTexSubImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, 0, 0, 0, 0, mWidth, mHeight);
    
    theError = glGetError();
	if(theError != GL_NO_ERROR) {
		NSLog(@"glCopyTexSubImage2D: 0x%04X", theError);
		success = NO;
	}
    
	glFlush();	
    theError = glGetError();
	if(theError != GL_NO_ERROR) {
		NSLog(@"glFlush: 0x%04X", theError);
		success = NO;
	}
    
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, (unsigned)save1);
	CGLUnlockContext(cgl_ctx);
	return (success);
}

-(CVPixelBufferRef)readScreenAsynchFinish
{
	CGLContextObj cgl_ctx = [mGLContext CGLContextObj]; CGLLockContext(cgl_ctx);
	GLint save1, save2, save3;
	GLenum theError = GL_NO_ERROR;
    
	glGetIntegerv(GL_TEXTURE_BINDING_RECTANGLE_EXT, &save1);    
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, mTextureName);
	glGetIntegerv(GL_PACK_ALIGNMENT, &save2);
	glPixelStorei(GL_PACK_ALIGNMENT, 4);
	glGetIntegerv(GL_PACK_ROW_LENGTH, &save3);
	glPixelStorei(GL_PACK_ROW_LENGTH, (unsigned)mBufferRowBytes / 4);
	glGetTexImage(GL_TEXTURE_RECTANGLE_ARB, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, mBaseAddress);
    
	theError = glGetError();
	if(theError != GL_NO_ERROR)
		NSLog(@"glGetTexImage: 0x%04X", theError);
    
	glPixelStorei(GL_PACK_ROW_LENGTH, save3);
	glPixelStorei(GL_PACK_ALIGNMENT, save2);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, (unsigned)save1);
	CGLUnlockContext(cgl_ctx);
	[self flipBuffer];
    
    // copy mouse image data into screen position (alpha needed). 
    unsigned int h,w,c_height, c_width;
    c_height = cursorRect.size.height;
    c_width = cursorRect.size.width;
    unsigned char *cp_temp, *position;
    float alpha;
    
    for (h = 0; h < c_height; h++) {
        // we're at line 0 of cursor image.
        for (w = 0; w < c_width; w++) {
            position = mBaseAddress + mBufferRowBytes * (mHeight - (unsigned)cursorPosition.y + h) + ((unsigned)cursorPosition.x + w) * 4;
            
            // test vertical out-of-bounds
            if (position < mBaseAddress || position > mBaseAddress + mHeight * mWidth * 4)
                continue;
                
            if (cursorPosition.x + w >= mWidth)
                continue;
                
            cp_temp = cursorImageBuffer + c_width * 4 * h + w * 4;
            
            #if __BIG_ENDIAN__
                alpha = cp_temp[0] / 255.0f;
                position[1] = (unsigned char)(cp_temp[1] * alpha + (1 - alpha) * position[1]);
                position[2] = (unsigned char)(cp_temp[2] * alpha + (1 - alpha) * position[2]);
                position[3] = (unsigned char)(cp_temp[3] * alpha + (1 - alpha) * position[3]);
            #else
                alpha = cp_temp[3] / 255.0f;
                position[0] = (unsigned char)(cp_temp[2] * alpha + (1 - alpha) * position[0]);
                position[1] = (unsigned char)(cp_temp[0] * alpha + (1 - alpha) * position[1]);
                position[2] = (unsigned char)(cp_temp[1] * alpha + (1 - alpha) * position[2]);
            #endif
        }
    }
    
    // check if we're registered
    /*id appDelegate = [[NSApplication sharedApplication] delegate];
    NSMutableString *reg = [[NSMutableString alloc] initWithString: @"a"];
    [appDelegate performSelector:@selector(isRegistered:) withObject:reg];
    if ([reg isEqualToString:@"2"]) {
        // append "UNREGISTERED MARK"
        for (h = 0; h < mHeight; h+=16) {
            position = mBaseAddress + mBufferRowBytes * h;
            memset(position, 238, mBufferRowBytes);
        }
    }
    */
    
	if (theError == GL_NO_ERROR)
		return (mPixelBuffer);
	else
		return (NULL);
}

-(NSTimeInterval)bufferReadTime
{
	return mRecordTime;
}

-(void)setBufferReadTime:(NSTimeInterval)aStartTime
{
	mStartTime = aStartTime;
}

-(XGQueueController *)queueController
{
	return mQueueController;
}

@end
