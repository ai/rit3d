presentation.slide 'origin', ($, $$, slide) ->
  example  = $$('mark')
  cube     = $$('.cube')
  prop     = "-#{presentation.prefix()}-perspective-origin"

  slide.every 100, ->
    example.text(cube.css(prop))
