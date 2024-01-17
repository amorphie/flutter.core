//
//  EnverifyDelegate.swift
//  Runner
//
//  Created by Hasolas on 17.01.2024.
//

import EnQualify

class EnverifyDelegate: EnVerifyDelegate {

    private lazy var handlerQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = .main
        return queue
    }()

    func luminosityAnalyzed(result: String) {
        
    }
    
    func agentRequest(eventData: String) {

    }
    
    func idVerifyReady() {

    }
    
    func idSelfVerifyReady() {

    }
    
    func callWait() {

    }
    
    func callStart() {

    }
    
    func idTypeCheck() {
        
    }
    
    func idTypeCheckCompleted() {
        
    }
    
    func idFakeCheck() {
        
    }
    
    func idFakeCheckCompleted() {
        
    }
    
    func idFront() {
        
    }
    
    func idFrontCompleted() {
        
    }
    
    func idBack() {
        
    }
    
    func idBackCompleted() {
        
    }
    
    func idDocCompleted() {
        
    }
    
    func nfcVerify() {
        
    }
    
    func nfcVerifyCompleted() {
        
    }
    
    func faceDetect() {
        
    }
    
    func faceDetectCompleted() {
        
    }
    
    func smileDetect() {
        
    }
    
    func smileDetectCompleted() {
        
    }
    
    func eyeClose() {
        
    }
    
    func eyeCloseDetected() {
        
    }
    
    func faceUp() {
        
    }
    
    func faceUpDetected() {
        
    }
    
    func faceLeft() {
        
    }
    
    func faceLeftDetected() {
        
    }
    
    func faceRight() {
        
    }
    
    func faceRightDetected() {
        
    }
    
    func eyeCloseInterval() {
        
    }
    
    func eyeCloseIntervalDetected() {
        
    }
    
    func eyeOpenInterval() {
        
    }
    
    func eyeOpenIntervalDetected() {
        
    }
    
    func hangupLocal() {
        
    }
    
    func hangupRemote() {
        
    }
    
    func failure() {
        
    }
    
    func tokenError() {
        
    }
    
    func noConnectionError() {
        
    }
    
    func idFakeDetected() {
        
    }
    
    func idDocStoreCompleted() {
        
    }
    
    func nfcStoreCompleted() {
        
    }
    
    func faceStoreCompleted() {
        
    }
    
    func idTypeBackCheck() {
        
    }
    
    func nfcCompleted() {
        
    }
    
    func faceCompleted() {
        
    }
    
    func idVerifyExited() {
        
    }
    
    func timeoutFailure() {
        
    }
    
    func idCheckFailure() {
        
    }
    
    func tokenFailure() {
        
    }
    
    func connectionFailure() {
        
    }
    
    func nfcFailure() {
        
    }
    
    func nfcBACDATAFailure() {
        
    }
    
    func faceLivenessCheckFailure() {
        
    }
    
    func idRetry() {
        
    }
    
    func nfcRetry() {
        
    }
    
    func faceRetry() {
        
    }
    
    func hostConnected() {
        
    }
    
    func resolutionChanged() {
        
    }
    
    func callConnectionFailure() {
        
    }
    
    func integrationAddCompleted() {
        
    }
    
    func integrationAddFailure() {
        
    }
    
    func resultGetCompleted(_ value: EnQualify.EnverifyVerifyCallResult?) {
        
    }
    
    func resultGetFailure() {
        
    }
    
    func sessionStartFailure() {
        
    }
    
    func sessionStartCompleted(sessionUid: String) {
        
    }
    
    func getAuthTokenFailure() {
        
    }
    
    func getAuthTokenCompleted() {
        
    }
    
    func getSettingsCompleted() {
        
    }
    
    func getSettingsFailure() {
        
    }
    
    func roomIDSendFailure() {
        
    }
    
    func roomIDSendCompleted() {
        
    }
    
    func idDocStoreFailure() {
        
    }
    
    func addChipStoreFailure() {
        
    }
    
    func addChipStoreCompleted() {
        
    }
    
    func addFaceCompleted() {
        
    }
    
    func addFaceFailure() {
        
    }
    
    func requestVideoAudioPermissionsResult(_ granted: Bool) {
        
    }
    
    func forceHangup() {
        
    }
    
    func idTextRecognitionTimeout() {
        
    }
    
    func callSessionCloseResult(status: EnQualify.EnVerifyCallSessionStatusTypeEnum) {
        
    }
    
    func dismissBeforeAnswered() {
        
    }
    
    func dismissCallWait() {
        
    }
    
    func screenRecorderOnStart() {
        
    }
    
    func screenRecorderOnComplete() {
        
    }
    
    func screenRecorderOnError(eventData: String) {
        
    }
    
    func screenRecorderOnAppend() {
        
    }
    
    func cardFrontDetectStarted() {
        
    }
    
    func cardFrontDetected() {
        
    }
    
    func cardBackDetectStarted() {
        
    }
    
    func cardBackDetected() {
        
    }
    
    func cardHoloDetectStarted() {
        
    }
    
    func cardHoloDetected() {
        
    }
    
    func videoUploadSuccess() {
        
    }
    
    func videoUploadFailure() {
        
    }
    
    func maximumCallTimeExpired() {
        
    }
    
    func currentThermalState(state: String) {

    }
}
