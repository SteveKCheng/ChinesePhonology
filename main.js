var g_soundCache = {};

function handlePlaySound(url, e)
{
    e.preventDefault();
    playSound(url); // play sound in background
}

async function playSound(url)
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

    await new Audio(cachedUrl).play();
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

    divBody = document.getElementById("body");
    divToc = document.getElementById("toc");

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

    document.getElementById("sidebar-button")
            .addEventListener("click", function(e) 
    {
        e.preventDefault();
        toggleSidebar(divToc.className == "collapsed");
    });

    // Make sidebar collapsed any time the user resizes the browser window too narrow.
    // (If no JavaScript code ever runs, the table of contents is set by CSS to be
    // always displayed statically near the beginning of the document.)
    narrowScreenQuery = window.matchMedia("screen and (width <= 40em)");
    function onNarrowScreenQueryChange() {
        toggleSidebar(!narrowScreenQuery.matches);
    }

    onNarrowScreenQueryChange();
    narrowScreenQuery.addEventListener("change", onNarrowScreenQueryChange);
});
