after = (ms, fn) -> setTimeout(fn, ms)
every = (ms, fn) -> setInterval(fn, ms)

# Удобства для написания скриптов слайдов

window.presentation =
  slide: (name, callback) ->
    jQuery ->
      slide = $(".slide.#{name}-slide")

      slide.open = (openCallback) ->
        presentation.onSlide (s) ->
          openCallback() if s.hasClass("#{name}-slide")
      slide.close = (closeCallback) ->
        presentation.onList(closeCallback)
        presentation.onSlide (s) ->
          closeCallback() unless s.hasClass("#{name}-slide")
      slide.every = (ms, fn) ->
        slide.open ->
          slide.watcher = setInterval(fn, 100)
        slide.close ->
          clearInterval(slide.watcher) if slide.watcher

      finder = (selector) -> $(selector, slide)
      callback($, finder, slide)

  prefix: ->
    return 'moz'    if $.browser.mozilla
    return 'webkit' if $.browser.webkit
    return 'o'      if $.browser.opera
    return 'ms'     if $.browser.msie

jQuery ($) ->

  # Открываем ссылки в новых вкладках

  $('a[href^=http]').attr(target: '_blank')

  # Перехватываем переключение между слайдами

  slideCallbacks = jQuery.Callbacks()
  closeCallbacks = jQuery.Callbacks()
  listCallbacks  = jQuery.Callbacks()
  listMode       = false
  currentSlide   = null

  urlChanged = ->
    closeCallbacks.fire()
    if location.search == '?full'
      listMode = false
      if currentSlide != location.hash
        currentSlide = location.hash
        slideCallbacks.fire($(location.hash))
    else
      currentSlide = null
      unless listMode
        listMode = true
        listCallbacks.fire()

  origin = {}
  for method in ['pushState', 'replaceState']
    do (method) ->
      origin[method]  = history[method]
      history[method] = ->
        origin[method].apply(history, arguments)
        urlChanged()
  $(window).on('popstate',   urlChanged)
  $(window).on('hashchange', urlChanged)

  presentation.onSlide = (callback) -> slideCallbacks.add(callback)
  presentation.onClose = (callback) ->  listCallbacks.add(callback)
  presentation.onList  = (callback) ->  listCallbacks.add(callback)

  # Включение/выключение 3D-режима

  mode3d = false

  presentation.onSlide (slide) ->
    if slide.hasClass('use3d')
      $('body').addClass('enabled3d')
    else
      $('body').removeClass('enabled3d')

  presentation.onList ->
    $('body').removeClass('enabled3d')

  # Выключаем GIF-анимацию в списке слайдов

  after 500, ->
    $('img.gif').each ->
      img    = $(@)
      canvas = document.createElement('canvas')
      canvas.width  = @.width
      canvas.height = @.height
      canvas.getContext('2d').drawImage(@, 0, 0, canvas.width, canvas.height)
      clone = $('<img />').
        attr(class: img.attr('class')).
        removeClass('gif').addClass('disabled-gif')
      try
        clone[0].src = canvas.toDataURL('image/gif')
        clone.insertAfter(@)
        $('body').addClass('disable-gif')
      catch error
        console.log("Can’t disable GIF-animation in development mode")

  # Анимируем автоматическоке наведение мышки на пример

  hovering = null

  presentation.onSlide (slide) ->
    hover = slide.find('.animate-hover')
    if hover.length
      hovering = every 3000, -> hover.toggleClass('hovered')

  presentation.onClose ->
    clearInterval(hovering)
