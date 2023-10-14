#ifndef Transcription-Bridging-Header_h
#define Transcription-Bridging-Header_h

#ifdef __cplusplus
extern "C" {
#endif

    // Define the callback types
    typedef void (*TranscriptionDoneCallback)(const char*);
    typedef void (*TranscriptionCallback)(const char*);

    // Function declarations
    void _SetTranscriptionDoneCallback(TranscriptionDoneCallback callback);
    void _SetTranscriptionCallback(TranscriptionCallback callback);
    void _StartRecording();
    void _StopRecording();

#ifdef __cplusplus
}
#endif

#endif /* TranscriptionControllerWrapper_h */
