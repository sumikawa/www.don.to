var initPhotoSwipeFromDOM;

initPhotoSwipeFromDOM = function (gallerySelector) {
  var hashData, i, onThumbnailsClick, openPhotoSwipe, parseThumbnailElements, photoswipeParseHash;
  parseThumbnailElements = function (el) {
    var figureEl, i, item, items, linkEl, numNodes, size, thumbElements;
    thumbElements = el.childNodes;
    numNodes = thumbElements.length;
    items = [];
    figureEl = void 0;
    linkEl = void 0;
    size = void 0;
    item = void 0;
    i = 0;

    // Replace jQuery selector with vanilla JS
    var swipeElements = document.querySelectorAll('a.swipe');
    for (var j = 0; j < swipeElements.length; j++) {
      var swipeEl = swipeElements[j];
      var height, href, id, poster, src, width;

      href = swipeEl.getAttribute('href');
      src = swipeEl.querySelector('img') ? swipeEl.querySelector('img').getAttribute('src') : '';

      if (swipeEl.classList.contains('image')) {
        item = {
          src: href,
          msrc: src,
          el: swipeEl
        };
      } else {
        id = href.replace(/.*\//, '').replace('.mp4', '');
        width = 480;
        if (id.match(/^hd/)) {
          height = 270;
        } else {
          height = 360;
        }
        if (id.match(/tr/)) {
          width = height;
          height = 480;
        }
        poster = src.replace(/video\/\d+/, 'video/' + height);
        item = {
          html: '<video controls style="padding-top: 40px; background: url(\'' + poster + '\') no-repeat 0 40px;" class="viodebackground"><source src="' + href + '" poster="' + poster + '" width="' + width + '" height="' + height + '" type="video/mp4"></video>',
          el: swipeEl
        };
      }
      items.push(item);
      i++;
    }
    return items;
  };

  onThumbnailsClick = function (e) {
    var clickedGallery, clickedListItem, eTarget, index;
    e = e || window.event;
    if (e.preventDefault) {
      e.preventDefault();
    } else {
      e.returnValue = false;
    }
    eTarget = e.target || e.srcElement;
    clickedListItem = eTarget;
    if (!clickedListItem) {
      return;
    }
    clickedGallery = clickedListItem.parentNode;
    index = clickedGallery.getAttribute('data-pswp-uid');
    if (index >= 0) {
      openPhotoSwipe(index - 1, clickedGallery);
    }
    return false;
  };

  photoswipeParseHash = function () {
    var hash, i, pair, params, vars;
    hash = window.location.hash.substring(1);
    params = {};
    if (hash.length < 5) {
      return params;
    }
    vars = hash.split('&');
    i = 0;
    while (i < vars.length) {
      if (!vars[i]) {
        i++;
        continue;
      }
      pair = vars[i].split('=');
      if (pair.length < 2) {
        i++;
        continue;
      }
      params[pair[0]] = pair[1];
      i++;
    }
    if (params.gid) {
      params.gid = parseInt(params.gid, 10);
    }
    return params;
  };

  openPhotoSwipe = function (index, galleryElement, disableAnimation, fromURL) {
    var gallery, items, j, options, pswpElement;
    pswpElement = document.querySelectorAll('.pswp')[0];
    gallery = void 0;
    options = void 0;
    items = parseThumbnailElements(galleryElement);
    options = {
      galleryUID: galleryElement.getAttribute('data-pswp-uid'),
      getThumbBoundsFn: function (index) {
        var pageYScroll, rect, thumbnail;
        thumbnail = items[index].el.getElementsByTagName('img')[0];
        pageYScroll = window.pageYOffset || document.documentElement.scrollTop;
        rect = thumbnail.getBoundingClientRect();
        return {
          x: rect.left,
          y: rect.top + pageYScroll,
          w: rect.width
        };
      },
      shareEl: false,
      bgOpacity: 1.0,
      dataSource: items,
      preload: [1, 5]
    };
    if (fromURL) {
      if (options.galleryPIDs) {
        j = 0;
        while (j < items.length) {
          if (items[j].pid === index) {
            options.index = j;
            break;
          }
          j++;
        }
      } else {
        options.index = parseInt(index, 10) - 1;
      }
    } else {
      options.index = parseInt(index, 10);
    }
    if (isNaN(options.index)) {
      return;
    }
    if (disableAnimation) {
      options.showAnimationDuration = 0;
    }
    gallery = new PhotoSwipe(options);
    gallery.init();
  };

  // Set up click handlers for all swipe elements
  i = 0;
  var swipeElements = document.querySelectorAll('a.swipe');
  for (var j = 0; j < swipeElements.length; j++) {
    var swipeEl = swipeElements[j];
    swipeEl.setAttribute('data-pswp-uid', i + 1);
    swipeEl.addEventListener('click', onThumbnailsClick);
    i++;
  }

  hashData = photoswipeParseHash();
  if (hashData.pid && hashData.gid) {
    var swipeElements = document.querySelectorAll('a.swipe');
    if (hashData.pid < swipeElements.length) {
      openPhotoSwipe(hashData.pid, swipeElements[hashData.pid], true, true);
    }
  }
};

// Replace jQuery document ready with vanilla JS
document.addEventListener('DOMContentLoaded', function () {
  initPhotoSwipeFromDOM('.mainblock');
});
