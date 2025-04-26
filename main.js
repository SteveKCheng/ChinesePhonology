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

document.addEventListener("DOMContentLoaded", function(e) {
    const items = document.querySelectorAll("a.audio");
    for (const item of items)
    {
        url = item.getAttribute("href");
        item.addEventListener("click", handlePlaySound.bind(null, url), false);
    }
});
