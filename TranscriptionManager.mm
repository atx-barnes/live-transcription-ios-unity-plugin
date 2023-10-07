//
//  TranscriptionManager.m
//
//  Created by Jackson Barnes on 10/6/23.
//  Copyright © 2023 Apple. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

@interface TranscriptionManager : NSObject

@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, strong) AVAudioEngine *audioEngine;

// Define a function type for the callback
typedef void (*TranscriptionCallback)(const char*);

// Store the callback for later use
@property (nonatomic) TranscriptionCallback s_transcriptionCallback;

//Class property to access the shared instance
@property (class, nonatomic, readonly) TranscriptionManager *sharedManager;

@end

@implementation TranscriptionManager

// Static variable for our shared instance
static TranscriptionManager *_sharedManager = nil;

// Class property to access the shared instance
+ (TranscriptionManager *)sharedManager {
    if (!_sharedManager) {
        _sharedManager = [[TranscriptionManager alloc] initPrivate];
    }
    return _sharedManager;
}

// Private init for internal use
- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return self;
}

// Overridden public init to avoid direct initialization
- (instancetype)init {
    [NSException raise:@"SingletonPattern" format:@"Use +[TranscriptionManager sharedManager], not -init"];
    return nil;
}

+ (void)startRecording {
    [[self sharedManager] startRecordingInstanceMethod];
}

- (void)startRecordingInstanceMethod {
    // Cancel the previous task if it's running.
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }

    // Configure the audio session for the app.
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *audioSessionError;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                         mode:AVAudioSessionModeDefault
                      options:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDefaultToSpeaker
                        error:&audioSessionError];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&audioSessionError];
    AVAudioInputNode *inputNode = _audioEngine.inputNode;

    // Create and configure the speech recognition request.
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    if (!_recognitionRequest) {
        NSLog(@"Unable to create a SFSpeechAudioBufferRecognitionRequest object");
        return;
    }
    _recognitionRequest.shouldReportPartialResults = YES;

    __weak __typeof__(self) weakSelf = self;
    _recognitionTask = [_speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        BOOL isFinal = NO;

        if (result) {
            isFinal = result.isFinal;

            SFTranscriptionSegment *lastSegment = result.bestTranscription.segments.lastObject;
            if (lastSegment && strongSelf.s_transcriptionCallback) {
                const char *transcription = [lastSegment.substring UTF8String];
                strongSelf.s_transcriptionCallback(transcription);
                NSLog(@"Transcribed segment: %@", lastSegment.substring);
            }
        }

        if (error || isFinal) {
            [strongSelf->_audioEngine stop];
            [inputNode removeTapOnBus:0];

            strongSelf->_recognitionRequest = nil;
            strongSelf->_recognitionTask = nil;
        }
    }];

    // Configure the microphone input.
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        [strongSelf->_recognitionRequest appendAudioPCMBuffer:buffer];
    }];

    [_audioEngine prepare];
    NSError *audioEngineStartError;
    [_audioEngine startAndReturnError:&audioEngineStartError];
    if (audioEngineStartError) {
        NSLog(@"Error starting audio engine: %@", audioEngineStartError.localizedDescription);
    }
}

+ (void)stopRecording {
    [[self sharedManager] stopRecordingInstanceMethod];
}

- (void)stopRecordingInstanceMethod {
    if ([_audioEngine isRunning]) {
        [_audioEngine stop];
        [_recognitionRequest endAudio];
    }
}

+(void)logTest {
    NSLog(@"Hello, World!");
}

@end

extern "C" {
    void _SetTranscriptionCallback(TranscriptionCallback callback) {
        [TranscriptionManager sharedManager].s_transcriptionCallback = callback;
    }

    void _StartRecording() {
        [TranscriptionManager startRecording];
    }

    void _StopRecording() {
        [TranscriptionManager stopRecording];
    }

    void _LogTest() {
        [TranscriptionManager logTest];
    }
}
