const FETCH_TIMER = 150;
let pls = document.querySelectorAll("a[href][preload]");

pls.forEach((link) => {
  let timeout;

  link.addEventListener("mouseover", (e) => {
    timeout = setTimeout(() => {
      fetchPage(link.href)
    }, FETCH_TIMER);
  });

  link.addEventListener("mouseout", (e) => {
    clearTimeout(timeout);
  })
})

async function fetchPage(url) {
  await fetch(url);
}
