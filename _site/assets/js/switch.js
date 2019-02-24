/* Toggle between showing and hiding the navigation menu links when the user clicks on the hamburger menu / bar icon */
function switchMenu(x) {
  x.classList.toggle("change");
  var x = document.getElementsByClassName("categories")[0];
  if (x.style.display === "block") {
    x.style.display = "none";
  } else {
    x.style.display = "block";
  }
} 
