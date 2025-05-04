// Cache of downloaded sound clips
var g_soundCache = {};

// Single HTML5 audio object for playing back sound clips.
// Sounds are not played simultaneously; if a new clip is started
// the one already playing is stopped.
var g_audio = null;

function handlePlaySound(url, e)
{
    if (g_audio == null)
        g_audio = new Audio();
    else
        g_audio.pause();

    e.preventDefault();
    playSound(g_audio, url); // play sound in background
}

async function playSound(audio, url)
{
    var cachedUrl;
    if (url in g_soundCache)
    {
        cachedUrl = g_soundCache[url];
    }
    else
    {
        blob = await (await fetch(url)).blob();
        cachedUrl = URL.createObjectURL(blob);
        g_soundCache[url] = cachedUrl;
    }

    audio.src = cachedUrl;
    await audio.play();
}

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
    const narrowScreenQuery = window.matchMedia("screen and (width <= 40em)");
    function onNarrowScreenQueryChange() {
        toggleSidebar(!narrowScreenQuery.matches);
    }

    onNarrowScreenQueryChange();
    narrowScreenQuery.addEventListener("change", onNarrowScreenQueryChange);
});
