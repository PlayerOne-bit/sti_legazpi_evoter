(function () {
  var api = String(window.EVOTER_API || "").replace(/\/+$/, "");
  var status = document.getElementById("status");
  var notesBox = document.getElementById("notes");
  var notesText = document.getElementById("notes-text");

  function mine() {
    var ua = navigator.userAgent || "";
    if (/Android/i.test(ua)) return "android";
    if (/Windows/i.test(ua)) return "windows";
    return null;
  }

  function mb(bytes) {
    return (bytes / (1024 * 1024)).toFixed(1) + " MB";
  }

  function field(card, name) {
    return card.querySelector('[data-field="' + name + '"]');
  }

  function setStatus(text, isError) {
    status.textContent = text;
    status.classList.toggle("error", !!isError);
  }

  function fill(platform, info) {
    var card = document.getElementById("card-" + platform);
    var button = field(card, "button");
    var meta = field(card, "meta");
    if (!info || !info.available || !info.url) {
      meta.textContent = "Not published yet";
      button.setAttribute("aria-disabled", "true");
      button.removeAttribute("href");
      return null;
    }
    meta.textContent = "Version " + info.version + "  ·  " + mb(info.size);
    button.href = info.url;
    button.setAttribute("aria-disabled", "false");
    button.setAttribute("download", "");
    return info;
  }

  function check(platform) {
    return fetch(api + "/api/app/update?platform=" + platform + "&build=0", { cache: "no-store" })
      .then(function (r) {
        if (!r.ok) throw new Error("HTTP " + r.status);
        return r.json();
      });
  }

  var preferred = mine();
  if (preferred) {
    var card = document.getElementById("card-" + preferred);
    card.classList.add("recommended");
    field(card, "badge").hidden = false;
    if (preferred === "windows") {
      card.parentNode.insertBefore(card, card.parentNode.firstChild);
    }
  }

  if (!api || api.indexOf("YOUR_DOMAIN") !== -1) {
    setStatus("Downloads are not set up yet. Set the server address in config.js.", true);
    return;
  }

  Promise.all([check("android"), check("windows")])
    .then(function (results) {
      var android = fill("android", results[0]);
      var windows = fill("windows", results[1]);
      var latest = android || windows;
      if (!latest) {
        setStatus("No version has been published yet. Check back soon.", false);
        return;
      }
      setStatus("Latest version " + latest.version, false);

      // The hero button downloads straight away for Android and Windows visitors.
      var mineInfo = preferred === "android" ? android : preferred === "windows" ? windows : null;
      var hero = document.getElementById("hero-download");
      if (hero && mineInfo) {
        hero.href = mineInfo.url;
        hero.setAttribute("download", "");
        hero.querySelector("span").textContent =
          "Download for " + (preferred === "android" ? "Android" : "Windows") + " · " + mineInfo.version;
      }
      if (latest.notes) {
        notesText.textContent = latest.notes;
        notesBox.hidden = false;
      }
    })
    .catch(function () {
      setStatus("Could not reach the eVoter server. Please try again in a moment.", true);
      fill("android", null);
      fill("windows", null);
    });
})();
