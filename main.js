// Cache of downloaded sound clips
var g_soundCache = {};

// Single HTML5 audio object for playing back sound clips.
// Sounds are not played simultaneously; if a new clip is started
// the one already playing is stopped.
//
// This object must be created on first use, from when the user
// selects a clip to play, because of (mobile) browser restrictions
// on what they would consider "auto-playing" sounds.
var g_audio = null;

// The OGV counterpart to g_audio, if needed. 
var g_ogvAudio = null;

// The async result from loadOggAudioSupport() below.
var g_ogvModulePromise = null;

// Dynamically load the OGV module if browser does not support Ogg.
async function loadOggAudioSupport() 
{
    const audio = new Audio();
    const supportsOgg = !!audio.canPlayType && 
        audio.canPlayType('audio/ogg; codecs="vorbis"') !== '';
    if (supportsOgg)
        return;

    const ogvUrl = "https://cdn.jsdelivr.net/npm/ogv@1.9.0/";
    const ogvModule = await import(ogvUrl + "+esm");
    ogvModule.OGVLoader.base = ogvUrl + "dist";
    return ogvModule;
}

function handlePlaySound(url, e)
{
    if (g_audio == null)
    {
        g_audio = new Audio();
    }
    else
    {
        g_audio.pause();
        if (g_ogvAudio != null)
            g_ogvAudio.pause();
    }

    e.preventDefault();
    playSound(url); // play sound in background
}

async function playSound(url)
{
    var descriptor;
    if (url in g_soundCache)
    {
        descriptor = g_soundCache[url];
    }
    else
    {
        blob = await (await fetch(url)).blob();
        descriptor = {
            mediaType: blob.type,
            cachedUrl: URL.createObjectURL(blob)
        };
        g_soundCache[url] = descriptor;
    }

    var audio = g_audio;

    // Use g_ogvAudio in place of g_audio if playing an Ogg file
    // but the browser does not support Ogg natively.
    const ogvModule = await g_ogvModulePromise;
    const mediaTypeRe = /^(application|audio)\/ogg($|;)/;
    if (ogvModule != null && mediaTypeRe.test(descriptor.mediaType))
    {
        if (g_ogvAudio == null)
            g_ogvAudio = new ogvModule.OGVPlayer();
        audio = g_ogvAudio;
    }    

    audio.src = descriptor.cachedUrl;
    await audio.play();
}

window.addEventListener("load", function(e)
{
    g_ogvModulePromise = loadOggAudioSupport();
});

document.addEventListener("DOMContentLoaded", function(e) 
{
    const items = document.querySelectorAll("a.audio");
    for (const item of items)
    {
        url = item.getAttribute("href");
        item.addEventListener("click", handlePlaySound.bind(null, url), false);
    }

    //
    // Set up initial state of the sidebar.
    //
    // For media other than interactive screens, e.g. print, 
    // the classes set on divBody and divToc do nothing as there are no
    // CSS rules for them; and the elements are always displayed statically
    // near the beginning of the document.
    // 

    const divBody = document.getElementById("body");
    const divToc = document.getElementById("toc");

    function toggleSidebar(toExpand) {
        if (toExpand)
        {
            divToc.className = "expanded";
            divBody.className = "sidebar-expanded";    
        }
        else
        {
            divToc.className = "collapsed";
            divBody.className = "sidebar-collapsed";    
        }
    }

    const divSidebarButton = document.getElementById("sidebar-button");
    divSidebarButton.addEventListener("click", function(e) {
        e.preventDefault();
        toggleSidebar(divToc.className == "collapsed");
    });

    // Pass through clicks on the content of divSidebarButton to the above
    // handler.  We set this CSS rule dynamically here so it does not apply
    // when JavaScript code does not run; then the button's behavior falls back
    // to being a plain link expressed through the <a> element in the HTML source.
    document.styleSheets[document.styleSheets.length - 1].insertRule(
        "div#sidebar-button * { pointer-events: none; }"
    );

    // Make sidebar collapsed any time the user resizes the browser window too narrow.
    // (If no JavaScript code ever runs, the table of contents is set by CSS to be
    // always displayed statically near the beginning of the document.)
    const narrowScreenQuery = window.matchMedia("screen and (width <= 65em)");
    function onNarrowScreenQueryChange() {
        toggleSidebar(!narrowScreenQuery.matches);
    }

    onNarrowScreenQueryChange();
    narrowScreenQuery.addEventListener("change", onNarrowScreenQueryChange);
});
