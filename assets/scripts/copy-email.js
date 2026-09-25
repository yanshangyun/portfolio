document.addEventListener('DOMContentLoaded', function () {
    var link = document.getElementById('email-link');
    if (!link) return;

    var original = link.textContent;
    var resetTimer = null;

    link.addEventListener('click', function (e) {
        e.preventDefault();
        var email = link.getAttribute('data-email');

        navigator.clipboard.writeText(email).then(function () {
            link.textContent = 'Copied!';
            clearTimeout(resetTimer);
            resetTimer = setTimeout(function () {
                link.textContent = original;
            }, 1000);
        });
    });
});
