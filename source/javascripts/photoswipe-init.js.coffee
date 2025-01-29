initPhotoSwipeFromDOM = (gallerySelector) ->
  # parse slide data (url, title, size ...) from DOM elements 
  # (children of gallerySelector)

  parseThumbnailElements = (el) ->
    thumbElements = el.childNodes
    numNodes = thumbElements.length
    items = []
    figureEl = undefined
    linkEl = undefined
    size = undefined
    item = undefined

    i = 0
    $('a.swipe').each ->
      href = $(this).attr('href')
      src = $(this).children().attr('src')
      if $(this).hasClass('image')
        item =
          src: href
          msrc: $(this).children().attr('src')
          w: 800
          h: 600
  #        w: parseInt(size[0], 10)
  #        h: parseInt(size[1], 10)
          el: this
      else
        id = href.replace(/.*\//, '').replace('.mp4', '')
        width = 480
        if id.match(/^hd/)
          height = 270
        else
          height = 360
        if id.match(/tr/)
          width = height
          height = 480
        poster = src.replace(/video\/\d+/, 'video/' + height)
        item =
          html: '<video controls style="padding-top: 40px; background: url(\'' + poster + '\') no-repeat 0 40px;" class="viodebackground"><source src="' + href + '" poster="' + poster + '" width="' + width + '" height="' + height + '" type="video/mp4"></video>'
          el: this
      items.push item
      i++
#    console.log(items)
    items

  # triggers when user clicks on thumbnail

  onThumbnailsClick = (e) ->
    e = e or window.event
    if e.preventDefault then e.preventDefault() else (e.returnValue = false)
    eTarget = e.target or e.srcElement
    # find root element of slide
    clickedListItem = eTarget
    if !clickedListItem
      return
    clickedGallery = clickedListItem.parentNode
    index = clickedGallery.getAttribute 'data-pswp-uid'
    if index >= 0
      # open PhotoSwipe if valid index found
      openPhotoSwipe index - 1, clickedGallery
    false

  # parse picture index and gallery index from URL (#&pid=1&gid=2)
  photoswipeParseHash = ->
    hash = window.location.hash.substring(1)
    params = {}
    if hash.length < 5
      return params
    vars = hash.split('&')
    i = 0
    while i < vars.length
      if !vars[i]
        i++
        continue
      pair = vars[i].split('=')
      if pair.length < 2
        i++
        continue
      params[pair[0]] = pair[1]
      i++
    if params.gid
      params.gid = parseInt(params.gid, 10)
    params

  openPhotoSwipe = (index, galleryElement, disableAnimation, fromURL) ->
    pswpElement = document.querySelectorAll('.pswp')[0]
    gallery = undefined
    options = undefined
    items = parseThumbnailElements(galleryElement)
    # define options (if needed)
    options =
      galleryUID: galleryElement.getAttribute('data-pswp-uid')
      getThumbBoundsFn: (index) ->
        # See Options -> getThumbBoundsFn section of documentation for more info
        thumbnail = items[index].el.getElementsByTagName('img')[0]
        pageYScroll = window.pageYOffset or document.documentElement.scrollTop
        rect = thumbnail.getBoundingClientRect()
        {
          x: rect.left
          y: rect.top + pageYScroll
          w: rect.width
        }
      shareEl: false
      preload: [1, 5]
    # PhotoSwipe opened from URL
    if fromURL
      if options.galleryPIDs
        # parse real index when custom PIDs are used 
        # http://photoswipe.com/documentation/faq.html#custom-pid-in-url
        j = 0
        while j < items.length
          if items[j].pid == index
            options.index = j
            break
          j++
      else
        # in URL indexes start from 1
        options.index = parseInt(index, 10) - 1
    else
      options.index = parseInt(index, 10)
    # exit if index not found
    if isNaN(options.index)
      return
    if disableAnimation
      options.showAnimationDuration = 0
    # Pass data to PhotoSwipe and initialize it
    gallery = new PhotoSwipe(pswpElement, PhotoSwipeUI_Default, items, options)
    gallery.init()
    return

  i = 0
  $('a.swipe').each ->
    this.setAttribute 'data-pswp-uid', i + 1
    $(this).click(onThumbnailsClick)
    i++

  # Parse URL and open gallery if it contains #&pid=3&gid=1
  hashData = photoswipeParseHash()
  if hashData.pid and hashData.gid
    openPhotoSwipe hashData.pid, $('a.swipe').eq(hashData.pid)[0], true, true
  return

# execute above function
$ ->
  initPhotoSwipeFromDOM '.mainblock'
