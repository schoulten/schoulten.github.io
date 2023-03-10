// Show/hide "about" text based on buttons
document.getElementById("abouten").style.display = "block";
document.getElementById("aboutpt").style.display = "none";

document.getElementById("English").addEventListener("click", function() {
  document.getElementById("abouten").style.display = "block";
  document.getElementById("aboutpt").style.display = "none";
});

document.getElementById("Portugues").addEventListener("click", function() {
  document.getElementById("abouten").style.display = "none";
  document.getElementById("aboutpt").style.display = "block";
});

// Show/hide "subtitle" text based on buttons
document.getElementById("suben").style.display = "block";
document.getElementById("subpt").style.display = "none";

document.getElementById("English").addEventListener("click", function() {
  document.getElementById("suben").style.display = "block";
  document.getElementById("subpt").style.display = "none";
});

document.getElementById("Portugues").addEventListener("click", function() {
  document.getElementById("suben").style.display = "none";
  document.getElementById("subpt").style.display = "block";
});