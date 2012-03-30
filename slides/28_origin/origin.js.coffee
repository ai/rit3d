presentation.slide 'origin', ($, $$, slide) ->
  watching = null
  cube     = $$('.cube')
  prop     = "-#{presentation.prefix()}-perspective-origin"
  example  = $$('mark')
  watch    = ->
    example.text(cube.css(prop))

  slide.open ->
    watching = setInterval(watch, 100)

  slide.close ->
    clearInterval(watching) if watching
