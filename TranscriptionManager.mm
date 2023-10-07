//
//  TranscriptionViewController.m
//  YourApp
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

@interface TranscriptionViewController : NSObject

@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, strong) AVAudioEngine *audioEngine;

// Define a function type for the callback
typedef void (*TranscriptionCallback)(const char*);

// Store the callback for later use
@property (nonatomic) TranscriptionCallback s_transcriptionCallback;

@end

@implementation TranscriptionViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return self;
}

- (void)startRecording {
    if (!_audioEngine.isRunning) {
        [self startRecordingInstanceMethod];
    }
}

- (void)startRecordingInstanceMethod {
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *audioSessionError;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                         mode:AVAudioSessionModeDefault
                      options:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDefaultToSpeaker
                        error:&audioSessionError];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&audioSessionError];
    AVAudioInputNode *inputNode = _audioEngine.inputNode;

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

    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [weakSelf.recognitionRequest appendAudioPCMBuffer:buffer];
    }];

    [_audioEngine prepare];
    NSError *audioEngineStartError;
    [_audioEngine startAndReturnError:&audioEngineStartError];
    if (audioEngineStartError) {
        NSLog(@"Error starting audio engine: %@", audioEngineStartError.localizedDescription);
    }
}

- (void)stopRecording {
    if ([_audioEngine isRunning]) {
        [_audioEngine stop];
        [_recognitionRequest endAudio];
    }
}

@end

extern "C" {
    TranscriptionViewController *transcriptionVC = nil;
    
    TranscriptionViewController *getTranscriptionVC() {
        if (transcriptionVC == nil) {
            transcriptionVC = [[TranscriptionViewController alloc] init];
        }
        return transcriptionVC;
    }

    void _SetTranscriptionCallback(TranscriptionCallback callback) {
        getTranscriptionVC().s_transcriptionCallback = callback;
    }

    void _StartRecording() {
        [getTranscriptionVC() startRecording];
    }

    void _StopRecording() {
        [getTranscriptionVC() stopRecording];
    }
}
