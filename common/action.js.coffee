jQuery ($) ->

  # Открываем ссылки в новых вкладках

  $('a[href^=http]').attr(target: '_blank')

  # Перехватываем переключение между слайдами

  slideCallbacks = jQuery.Callbacks()
  listCallbacks  = jQuery.Callbacks()
  listMode       = false
  currentSlide   = null

  urlChanged = ->
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

  onSlide  = (callback) -> slideCallbacks.add(callback)
  onList   = (callback) ->  listCallbacks.add(callback)

  # Включение/выключение 3D-режима

  mode3d = false

  onSlide (slide) ->
    if slide.hasClass('use3d')
      $('body').addClass('enabled3d')
    else
      $('body').removeClass('enabled3d')

  onList ->
    $('body').addClass('enabled3d')
