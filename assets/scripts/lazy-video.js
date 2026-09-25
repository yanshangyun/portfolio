document.addEventListener('DOMContentLoaded', function () {
    var videos = document.querySelectorAll('video[data-src]');

    function tryPlay(video) {
        if (!video.isConnected) return;
        video.play().catch(function () {
            // playback can be rejected while data is still loading (e.g. large
            // or non-faststart files); retry once the browser is ready.
            video.addEventListener('canplay', function onCanPlay() {
                video.removeEventListener('canplay', onCanPlay);
                video.play().catch(function () {});
            });
        });
    }

    var shouldPlay = new WeakSet();

    var observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
            var video = entry.target;
            if (entry.isIntersecting) {
                shouldPlay.add(video);
                if (!video.src) {
                    video.src = video.getAttribute('data-src');
                    video.load();
                }
                tryPlay(video);
            } else {
                shouldPlay.delete(video);
                video.pause();
            }
        });
    }, {
        root: null,
        rootMargin: '200px 0px',
        threshold: 0
    });

    videos.forEach(function (video) {
        observer.observe(video);

        // Chrome/Safari can pause background-tab video for power saving; resume
        // it if it's still meant to be playing once it comes back.
        video.addEventListener('pause', function () {
            if (shouldPlay.has(video)) {
                tryPlay(video);
            }
        });
    });

    document.addEventListener('visibilitychange', function () {
        if (document.visibilityState !== 'visible') return;
        videos.forEach(function (video) {
            if (shouldPlay.has(video) && video.paused) {
                tryPlay(video);
            }
        });
    });
});
