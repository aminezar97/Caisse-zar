document.getElementById("year").textContent = new Date().getFullYear();

const langBtn = document.getElementById("langBtn");
let arabic = false;

langBtn.addEventListener("click", () => {
  arabic = !arabic;
  document.documentElement.dir = arabic ? "rtl" : "ltr";
  document.documentElement.lang = arabic ? "ar" : "fr";
  langBtn.textContent = arabic ? "Français" : "العربية";

  document.querySelector(".eyebrow").textContent = arabic ? "نقطة بيع • المغرب" : "POINT DE VENTE • MAROC";
  document.querySelector("h1").innerHTML = arabic
    ? "كاشير عصري لـ <span>متجرك الصغير.</span>"
    : "Une caisse moderne pour votre <span>mini‑marché.</span>";
  document.querySelector(".lead").textContent = arabic
    ? "Zarouali Caisse هو نظام POS باللمس مخصص للبيع، إدارة المنتجات والمخزون والعمل بدون إنترنت."
    : "Zarouali Caisse est une solution POS tactile pensée pour la vente, le catalogue produits, le stock et l'utilisation hors ligne.";
  document.querySelector('a[href="#download"]').textContent = arabic ? "التحميل" : "Voir les téléchargements";
  document.querySelector('a[href="#features"]').textContent = arabic ? "المميزات" : "Fonctionnalités";
  document.querySelector('a[href="#offline"]').textContent = arabic ? "بدون إنترنت" : "Hors ligne";
  document.querySelector('a[href="#download"]').textContent = arabic ? "التحميل" : "Téléchargement";
});
