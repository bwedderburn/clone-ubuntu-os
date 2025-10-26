// Multi Time Zone Clock
// - Saves zones to localStorage
// - Uses Intl.DateTimeFormat to render time for IANA time zones
// - Allows adding by selecting common zones or entering a custom IANA name

const DEFAULT_ZONES = [
  "local",
  "UTC",
  "America/New_York",
  "Europe/London",
  "Europe/Berlin",
  "Asia/Tokyo",
  "Australia/Sydney",
  "America/Los_Angeles"
];

const tzInput = document.getElementById("tz-input");
const tzList = document.getElementById("tz-list");
const addBtn = document.getElementById("add-btn");
const clocksEl = document.getElementById("clocks");
const formatToggle = document.getElementById("format-toggle");

let zones = loadZones();
let use24 = load24();

function loadZones(){
  try{
    const raw = localStorage.getItem("multi-tz-zones");
    if(!raw) return DEFAULT_ZONES.slice();
    return JSON.parse(raw);
  }catch(e){
    return DEFAULT_ZONES.slice();
  }
}
function saveZones(){
  localStorage.setItem("multi-tz-zones", JSON.stringify(zones));
}
function load24(){
  return localStorage.getItem("multi-tz-24") === "1";
}
function save24(){
  localStorage.setItem("multi-tz-24", use24 ? "1" : "0");
}

function isValidTimezone(tz){
  if(tz === "local") return true;
  try{
    new Intl.DateTimeFormat("en-US", {timeZone: tz});
    return true;
  }catch(e){
    return false;
  }
}

function nicelyName(tz){
  if(tz === "local") return `Local (${Intl.DateTimeFormat().resolvedOptions().timeZone || 'Local'})`;
  return tz.replace("_", " ");
}

function renderClocks(){
  clocksEl.innerHTML = "";
  zones.forEach((tz, idx) => {
    const card = document.createElement("article");
    card.className = "clock";
    card.dataset.tz = tz;

    const label = document.createElement("div");
    label.className = "label";

    const name = document.createElement("div");
    name.innerHTML = `<div class="zone-name">${nicelyName(tz)}</div><div class="zone-region">${tz === "local" ? "Local System" : "IANA"}</div>`;

    const remove = document.createElement("button");
    remove.className = "remove";
    remove.title = "Remove timezone";
    remove.textContent = "Remove";
    remove.addEventListener("click", () => {
      zones.splice(idx,1);
      saveZones();
      renderClocks();
    });

    label.appendChild(name);
    label.appendChild(remove);

    const timeEl = document.createElement("div");
    timeEl.className = "time";
    timeEl.textContent = "...";

    const dateEl = document.createElement("div");
    dateEl.className = "date";
    dateEl.textContent = "";

    card.appendChild(label);
    card.appendChild(timeEl);
    card.appendChild(dateEl);

    clocksEl.appendChild(card);
  });
}

function updateAll(){
  const now = new Date();
  document.querySelectorAll(".clock").forEach(card => {
    const tz = card.dataset.tz;
    const timeEl = card.querySelector(".time");
    const dateEl = card.querySelector(".date");

    let optsTime = {
      hour: "numeric",
      minute: "2-digit",
      second: "2-digit",
      hour12: !use24
    };
    let optsDate = {
      weekday: "short",
      year: "numeric",
      month: "short",
      day: "numeric"
    };

    let timeFormatter, dateFormatter;
    if(tz === "local"){
      timeFormatter = new Intl.DateTimeFormat(undefined, optsTime);
      dateFormatter = new Intl.DateTimeFormat(undefined, optsDate);
    } else {
      timeFormatter = new Intl.DateTimeFormat("en-GB", {...optsTime, timeZone: tz});
      dateFormatter = new Intl.DateTimeFormat("en-GB", {...optsDate, timeZone: tz});
    }

    timeEl.textContent = timeFormatter.format(now);
    dateEl.textContent = dateFormatter.format(now);
  });
}

// Populate datalist with common IANA zones for convenience
function populateDatalist(){
  const common = [
    "UTC",
    "local",
    "America/New_York",
    "America/Chicago",
    "America/Denver",
    "America/Los_Angeles",
    "Europe/London",
    "Europe/Berlin",
    "Europe/Paris",
    "Asia/Tokyo",
    "Asia/Shanghai",
    "Asia/Kolkata",
    "Australia/Sydney"
  ];
  tzList.innerHTML = "";
  common.forEach(tz=>{
    const opt = document.createElement("option");
    opt.value = tz;
    tzList.appendChild(opt);
  });
}

// Add button handler
addBtn.addEventListener("click", () => {
  const v = (tzInput.value || "").trim();
  if(!v) return;
  if(!isValidTimezone(v)){
    alert("Invalid or unknown IANA timezone name. Use a value like 'America/New_York' or 'UTC'.");
    return;
  }
  if(zones.includes(v)){
    // move to front
    zones = zones.filter(z => z !== v);
  }
  zones.unshift(v);
  saveZones();
  renderClocks();
  tzInput.value = "";
});

// toggle 24-hour
formatToggle.checked = use24;
formatToggle.addEventListener("change", () => {
  use24 = formatToggle.checked;
  save24();
  updateAll();
});

// initialize
populateDatalist();
renderClocks();
updateAll();
setInterval(updateAll, 1000);