var initPhotoSwipeFromDOM;

initPhotoSwipeFromDOM = function (gallerySelector) {
  var scope = document.querySelector(gallerySelector) || document;
  var getSwipeElements = function () {
    return scope.querySelectorAll('a.swipe');
  };

  var buildVideoItem = function (swipeEl, href, src) {
    var height;
    var id = href.replace(/.*\//, '').replace('.mp4', '');
    var width = 480;

    if (id.match(/^hd/)) {
      height = 270;
    } else {
      height = 360;
    }
    if (id.match(/tr/)) {
      width = height;
      height = 480;
    }

    var poster = src.replace(/video\/\d+/, 'video/' + height);
    return {
      html: '<div class="videoblock"><video controls style="background: url(\'' + poster + '\') no-repeat 0 0;" class="videobackground"><source src="' + href + '" poster="' + poster + '" width="' + width + '" height="' + height + '" type="video/mp4"></video></div>',
      el: swipeEl
    };
  };

  var parseThumbnailElements = function () {
    var items = [];
    var swipeElements = getSwipeElements();

    for (var i = 0; i < swipeElements.length; i++) {
      var swipeEl = swipeElements[i];
      var href = swipeEl.getAttribute('href') + '#t=0.001'; // https://stackoverflow.com/questions/18613470/why-safari-on-ios-is-not-showing-my-html5-video-poster
      var image = swipeEl.querySelector('img');
      var src = image ? image.getAttribute('src') : '';

      if (swipeEl.classList.contains('image')) {
        items.push({
          src: href,
          msrc: src,
          el: swipeEl
        });
      } else {
        items.push(buildVideoItem(swipeEl, href, src));
      }
    }

    return items;
  };

  var openPhotoSwipe = function (index, disableAnimation, fromURL) {
    var items = parseThumbnailElements();
    var options = {
      maxZoomLevel: 4,
      bgOpacity: 1.0,
      dataSource: items,
      preload: [1, 5]
    };

    if (fromURL) {
      options.index = parseInt(index, 10) - 1;
    } else {
      options.index = parseInt(index, 10);
    }
    if (isNaN(options.index)) {
      return;
    }
    if (disableAnimation) {
      options.showAnimationDuration = 0;
    }

    var gallery = new PhotoSwipe(options);
    gallery.init();
  };

  var onThumbnailsClick = function (e) {
    var event = e || window.event;
    if (event.preventDefault) {
      event.preventDefault();
    } else {
      event.returnValue = false;
    }

    var swipeEl = event.currentTarget || event.target || event.srcElement;
    if (!swipeEl) {
      return false;
    }

    var index = swipeEl.getAttribute('data-pswp-uid');
    if (index >= 0) {
      openPhotoSwipe(index - 1);
    }

    return false;
  };

  var photoswipeParseHash = function () {
    var hash = window.location.hash.substring(1);
    var params = {};
    if (hash.length < 5) {
      return params;
    }

    var vars = hash.split('&');
    for (var i = 0; i < vars.length; i++) {
      if (!vars[i]) {
        continue;
      }

      var pair = vars[i].split('=');
      if (pair.length < 2) {
        continue;
      }

      params[pair[0]] = pair[1];
    }
    if (params.gid) {
      params.gid = parseInt(params.gid, 10);
    }
    return params;
  };

  // Set up click handlers for all swipe elements
  var swipeElements = getSwipeElements();
  for (var j = 0; j < swipeElements.length; j++) {
    var swipeEl = swipeElements[j];
    swipeEl.setAttribute('data-pswp-uid', j + 1);
    swipeEl.addEventListener('click', onThumbnailsClick);
  }

  var hashData = photoswipeParseHash();
  if (hashData.pid && hashData.gid) {
    if (hashData.pid < swipeElements.length) {
      openPhotoSwipe(hashData.pid, true, true);
    }
  }
};

document.addEventListener('DOMContentLoaded', function () {
  initPhotoSwipeFromDOM('.mainblock');
});
