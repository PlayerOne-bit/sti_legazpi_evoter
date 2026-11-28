// Version history shown on the download page. Newest first.
// Small fix releases are grouped with the version they came with. Keep in step with README.md.
window.EVOTER_HISTORY = [
  {
    versions: "1.1.1",
    date: "November 29, 2026",
    title: "Senior high strands and tracks",
    changes: [
      "Grade 11 and 12 students get a Traditional strand or a Modern track (ACAD or TECH), picked with a toggle when adding a student.",
      "Excel import can convert strands to modern tracks: ABM, ASSH, BE, STEM and HUMSS become ACAD; MAWD and ICT become TECH.",
      "Grade 7 to 10 students are saved as JHS, and import files may write levels as plain numbers like 11."
    ]
  },
  {
    versions: "1.1.0",
    date: "November 29, 2026",
    title: "Season reminders and public results",
    changes: [
      "Receive in-app reminders 72, 48 and 24 hours before voting starts, plus an announcement when voting opens.",
      "See finalized election results when they are announced, including from the sign-in screen history.",
      "Candidates cannot vote in the season they are running in.",
      "Student dashboards focus on seasons that have candidates."
    ]
  },
  {
    versions: "1.0.9",
    date: "November 27, 2026",
    title: "Season email progress",
    changes: [
      "Track emailed passwords and remaining students in the season voter list.",
      "A live countdown shows when the next Gmail batch can run after reaching the rolling 24-hour limit.",
      "Continue with students who have not received their password yet, without resending the previous batch."
    ]
  },
  {
    versions: "1.0.7 – 1.0.8",
    date: "November 25, 2026",
    title: "Landscape and student editing",
    changes: [
      "Works on phones held sideways, including a full-height student list.",
      "The super admin can edit student details. Student numbers and full names must be unique.",
      "Positions are created right in the Add candidate dialog, and Create voting season is a floating button."
    ]
  },
  {
    versions: "1.0.6",
    date: "November 25, 2026",
    title: "One season per sign-in",
    changes: [
      "Signing in opens only the season your password belongs to.",
      "Seasons with no candidates are removed automatically when voting opens.",
      "Students from past school years are updated when they are added again for the new school year."
    ]
  },
  {
    versions: "1.0.4 – 1.0.5",
    date: "November 25, 2026",
    title: "Seasons on the sign-in screen",
    changes: [
      "See seasons voting now and coming up on the sign-in screen, with live countdowns.",
      "New calendar for season dates: the chosen days are joined in blue, and days taken by another season are circled in red.",
      "Seasons are locked once voting starts."
    ]
  },
  {
    versions: "1.0.1 – 1.0.3",
    date: "November 25, 2026",
    title: "Minor fixes",
    minor: true,
    changes: [
      "New app icon with the STI eVoter logo.",
      "Fixed the Windows app closing right after it opens. If you installed 1.0.1 on Windows, download the app again.",
      "The app version is shown on the sign-in screen."
    ]
  },
  {
    versions: "1.0.0",
    date: "November 25, 2026",
    title: "First release",
    changes: [
      "Sign in with your student number and season password, vote once per position, and see the results after the tally.",
      "Season passwords can be emailed to your school address.",
      "Light and dark mode, and updates from inside the app."
    ]
  }
];

(function () {
  var list = document.getElementById("history-list");
  if (!list || !window.EVOTER_HISTORY) return;

  window.EVOTER_HISTORY.forEach(function (entry, i) {
    var item = document.createElement("details");
    item.className = "release";
    if (i === 0) item.open = true;

    var summary = document.createElement("summary");
    var version = document.createElement("span");
    version.className = "release-version";
    version.textContent = entry.versions;
    var title = document.createElement("span");
    title.className = "release-title";
    title.textContent = entry.title;
    summary.appendChild(version);
    summary.appendChild(title);
    if (i === 0 || entry.minor) {
      var tag = document.createElement("span");
      tag.className = "release-tag" + (i === 0 ? " latest" : "");
      tag.textContent = i === 0 ? "Latest" : "Fixes";
      summary.appendChild(tag);
    }
    var date = document.createElement("span");
    date.className = "release-date";
    date.textContent = entry.date;
    summary.appendChild(date);
    item.appendChild(summary);

    var ul = document.createElement("ul");
    entry.changes.forEach(function (text) {
      var li = document.createElement("li");
      li.textContent = text;
      ul.appendChild(li);
    });
    item.appendChild(ul);
    list.appendChild(item);
  });
})();
