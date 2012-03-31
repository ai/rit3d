presentation.slide 'origin', ($, $$, slide) ->
  watching = null
  cube     = $$('.cube')
  prop     = "-#{presentation.prefix()}-perspective-origin"
  example  = $$('mark')

  slide.every 100, ->
    example.text(cube.css(prop))
