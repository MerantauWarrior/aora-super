document.addEventListener("DOMContentLoaded", function () {
  // landing menu
  var allItems = document.getElementsByClassName('landing-menu__item');
  for(var i = 0; i < allItems.length; i++){
    allItems[i].classList.add('landing-menu__item_opened');
    if(i>5 && i<allItems.length){
      allItems[i].classList.remove('landing-menu__item_opened');
    }
  }
  var landingToggle = document.getElementsByClassName('landing-menu__toggle')[0];
  if(typeof(landingToggle) != 'undefined' && landingToggle != null){
    landingToggle.addEventListener('click', function () {
      this.classList.toggle('landing-menu__toggle_opened');
      var allItems = document.getElementsByClassName('landing-menu__item');
      for(var i = 0; i < allItems.length; i++){
        allItems[i].style.height = allItems[i].style.height === '63px' ? '44px' : '63px';
        if(i>5 && i<allItems.length){
          allItems[i].classList.toggle('landing-menu__item_opened')
        }
      }
    });
  }
  //  main menu
  document.getElementsByClassName('navigation-menu-btn')[0].addEventListener('click', function () {
    this.classList.toggle('navigation-menu-btn_opened');
    if(this.getAttribute('title') === 'Click to close'){
      this.setAttribute('title', 'Click to open');
    }else {
      this.setAttribute('title', 'Click to close');
    }
    document.getElementsByClassName('navigation-menu')[0].classList.toggle('navigation-menu_opened');
  });


});