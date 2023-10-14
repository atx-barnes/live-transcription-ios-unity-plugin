#import "Transcription-Swift.h"

extern "C" {
    static TranscriptionController* transcriptionController = nil;

    TranscriptionController* getTranscriptionController() {
        if (!transcriptionController) {
            transcriptionController = [[TranscriptionController alloc] init];
        }
        return transcriptionController;
    }

    void _SetTranscriptionDoneCallback(void(*callback)(const char*)) {
        [getTranscriptionController() setTranscriptionDoneCallback:^(NSString* finalTranscription){
            callback([finalTranscription UTF8String]);
        }];
    }

    void _SetTranscriptionCallback(void(*callback)(const char*)) {
        [getTranscriptionController() setTranscriptionCallback:^(NSString* partialTranscription) {
            callback([partialTranscription UTF8String]);
        }];
    }

    void _StartRecording() {
        [getTranscriptionController() startRecording];
    }

    void _StopRecording() {
        [getTranscriptionController() stopRecording];
    }
}
