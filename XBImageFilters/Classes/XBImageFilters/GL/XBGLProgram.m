//
//  XBGLProgram.m
//  XBImageFilters
//
//  Created by xiss burg on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBGLProgram.h"
#import "XBGLEngine.h"

NSString *const XBGLProgramErrorDomain = @"GLKProgramErrorDomain";

@interface XBGLProgram ()

@property (readonly, copy, nonatomic) NSDictionary *uniforms;
@property (strong, nonatomic) NSMutableDictionary *dirtyUniforms;
@property (strong, nonatomic) NSMutableDictionary *samplerBindings;
@property (strong, nonatomic) NSMutableDictionary *samplerXBBindings;

@end

@implementation XBGLProgram

@synthesize uniforms = _uniforms;
@synthesize attributes = _attributes;
@synthesize dirtyUniforms = _dirtyUniforms;
@synthesize program = _program;
@synthesize samplerBindings = _samplerBindings;
@synthesize samplerXBBindings = _samplerXBBindings;

- (id)initWithVertexShaderFromFile:(NSString *)vertexShaderPath fragmentShaderFromFile:(NSString *)fragmentShaderPath error:(NSError *__autoreleasing *)error
{
    NSString *vertexShaderSource = [[NSString alloc] initWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:error];
    
    if (vertexShaderSource == nil) {
        return nil;
    }
    
    NSString *fragmentShaderSource = [[NSString alloc] initWithContentsOfFile:fragmentShaderPath encoding:NSUTF8StringEncoding error:error];
    
    if (fragmentShaderSource == nil) {
        return nil;
    }
    
    return [self initWithVertexShaderSource:vertexShaderSource fragmentShaderSource:fragmentShaderSource error:error];
}

- (id)initWithVertexShaderSource:(NSString *)vertexShaderSource fragmentShaderSource:(NSString *)fragmentShaderSource error:(NSError *__autoreleasing *)error
{
    self = [super init];
    if (self) {
        _program = [[XBGLEngine sharedInstance] createProgramWithVertexShaderSource:vertexShaderSource fragmentShaderSource:fragmentShaderSource error:error];
        
        if (self.program == 0) {
            return nil;
        }
        
        _uniforms = [[XBGLEngine sharedInstance] uniformsForProgram:self.program];
        _attributes = [[XBGLEngine sharedInstance] attributesForProgram:self.program];
        self.samplerBindings = [[NSMutableDictionary alloc] init];
        self.samplerXBBindings = [[NSMutableDictionary alloc] init];
        self.dirtyUniforms = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[XBGLEngine sharedInstance] deleteProgram:self.program];
}

#pragma mark - Methods

- (void)setValue:(void *)value forUniformNamed:(NSString *)uniformName
{
    XBGLShaderUniform *uniform = [self.uniforms objectForKey:uniformName];
    uniform.value = value;
    [self.dirtyUniforms setObject:uniform forKey:uniform.name];
}

- (void)bindSamplerNamed:(NSString *)samplerName toXBTexture:(XBGLTexture *)texture unit:(GLint)unit
{
    [self setValue:&unit forUniformNamed:samplerName];
    
    if (texture != nil) {
        [self.samplerXBBindings setObject:texture forKey:samplerName];
    }
    else {
        [self.samplerXBBindings removeObjectForKey:samplerName];
    }
}

- (void)bindSamplerNamed:(NSString *)samplerName toTexture:(GLuint)texture unit:(GLint)unit
{
    [self setValue:&unit forUniformNamed:samplerName];
    
    if (texture != 0) {
        [self.samplerBindings setObject:[NSNumber numberWithUnsignedInt:texture] forKey:samplerName];
    }
    else {
        [self.samplerBindings removeObjectForKey:samplerName];
    }
}

- (void)prepareToDraw
{
    [[XBGLEngine sharedInstance] useProgram:self.program];
    
    // Flush dirty uniforms
    for (NSString *name in [self.dirtyUniforms allKeys]) {
        XBGLShaderUniform *uniform = [self.dirtyUniforms objectForKey:name];
        [[XBGLEngine sharedInstance] flushUniform:uniform];
    }
    
    [self.dirtyUniforms removeAllObjects];
    
    // Set textures
    for (id key in [self.samplerBindings allKeys]) {
        XBGLShaderUniform *uniform = [self.uniforms objectForKey:key];
        XBGLTexture *texture = [self.samplerXBBindings objectForKey:key];
        if (texture != nil) {
            [[XBGLEngine sharedInstance] bindTexture:texture.name unit:*(GLint *)uniform.value];
        }
        else {
            NSNumber *textureNumber = [self.samplerBindings objectForKey:uniform.name];
            if (textureNumber != nil) {
                [[XBGLEngine sharedInstance] bindTexture:textureNumber.unsignedIntValue unit:*(GLint *)uniform.value];
            }
        }
    }
}

@end