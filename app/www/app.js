// Menu hamburguesa
document.addEventListener("DOMContentLoaded", function () {
  var btn = document.getElementById("hamburger-btn");
  var nav = document.getElementById("nav-mobile");

  if (btn && nav) {
    btn.addEventListener("click", function () {
      btn.classList.toggle("active");
      nav.classList.toggle("open");
    });

    // Cerrar menu al hacer click en un link
    nav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", function () {
        btn.classList.remove("active");
        nav.classList.remove("open");
      });
    });
  }
});
