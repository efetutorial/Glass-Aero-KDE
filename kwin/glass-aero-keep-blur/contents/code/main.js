// SPDX-License-Identifier: GPL-3.0-or-later
// KWin 6.7 WindowForceBlurRole. Limit the effect to KDE applications.
var forceBlurRole = 5;
var watched = [];
function matches(window) {
    return window && !window.deleted &&
        /(^|\s)(dolphin|systemsettings|org\.kde\.[a-z0-9_.-]+)(\s|$)/i.test(String(window.windowClass));
}
function keepBlur(window) {
    if (matches(window) && window.data(forceBlurRole) !== true)
        window.setData(forceBlurRole, true);
}
function watch(window) {
    if (!matches(window)) return;
    if (watched.indexOf(window) < 0) {
        watched.push(window);
        window.windowStartUserMovedResized.connect(function() { keepBlur(window); });
        window.windowStepUserMovedResized.connect(function() { keepBlur(window); });
        window.windowFinishUserMovedResized.connect(function() { keepBlur(window); });
    }
    keepBlur(window);
}
effects.windowDataChanged.connect(function(window, role) {
    if (role === forceBlurRole) keepBlur(window);
});
effects.windowAdded.connect(watch);
effects.windowActivated.connect(watch);
effects.windowDeleted.connect(function(window) {
    var i = watched.indexOf(window);
    if (i >= 0) watched.splice(i, 1);
});
var windows = effects.stackingOrder;
for (var i = 0; i < windows.length; ++i) watch(windows[i]);
