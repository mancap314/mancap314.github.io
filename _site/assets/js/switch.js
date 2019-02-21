/* Toggle between showing and hiding the navigation menu links when the user clicks on the hamburger menu / bar icon */
function switchMenu() {
  var x = document.getElementById("categories");
  if (x.style.display === "block") {
    x.style.display = "none";
  } else {
    x.style.display = "block";
  }
} 
