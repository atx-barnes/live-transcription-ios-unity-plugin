#import "Transcription-Swift.h"

extern "C" {
    static TranscriptionController* transcriptionController = nil;

    TranscriptionController* getTranscriptionController() {
        if (!transcriptionController) {
            transcriptionController = [[TranscriptionController alloc] init];
        }
        return transcriptionController;
    }

    void _SetTranscriptionDoneCallback(void(*callback)()) {
        [getTranscriptionController() setTranscriptionDoneCallback:^{
            callback();
        }];
    }

    void _SetTranscriptionCallback(void(*callback)(const char*)) {
        [getTranscriptionController() setTranscriptionCallback:^(NSString* transcription) {
            callback([transcription UTF8String]);
        }];
    }

    void _StartRecording() {
        [getTranscriptionController() startRecording];
    }

    void _StopRecording() {
        [getTranscriptionController() stopRecording];
    }
}
