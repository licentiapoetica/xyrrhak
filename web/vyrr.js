(() => {
  const video = document.querySelector("video");

  if (video) {
    let saved = null;
    try {
      saved = JSON.parse(localStorage.getItem("vyrr"));
    } catch {}
    video.volume = typeof saved?.volume === "number" ? saved.volume : 0.5;
    video.muted = saved?.muted === true;
    video.addEventListener("volumechange", () => {
      try {
        localStorage.setItem("vyrr", JSON.stringify({ volume: video.volume, muted: video.muted }));
      } catch {}
    });
  }

  const follow = (rel) => {
    const link = document.querySelector(`a[rel=${rel}]`);
    if (link) location.href = link.href;
  };

  document.addEventListener("keydown", (e) => {
    if (e.ctrlKey || e.metaKey || e.altKey) return;
    if (e.target instanceof Element && e.target.closest("input, textarea, select")) return;

    if (e.key === "r" || e.key === "R") {
      e.preventDefault();
      const form = document.querySelector('form[action="/random"]');
      if (form) form.submit();
      else location.href = "/random";
    } else if (e.key === "ArrowRight") {
      e.preventDefault();
      follow("next");
    } else if (e.key === "ArrowLeft") {
      e.preventDefault();
      follow("prev");
    }
  });
})();
