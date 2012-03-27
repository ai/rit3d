require 'pathname'
ROOT   = Pathname(__FILE__).dirname
PUBLIC = ROOT.join('public')
SLIDES = ROOT.join('slides')
COMMON = ROOT.join('common')
VENDOR = ROOT.join('vendor')

require 'haml'
require 'compass'
require 'animation'
require 'coffee-script'

Compass.configuration.images_path = ROOT.to_s
Compass.configuration.fonts_path  = VENDOR.to_s

class Pathname
  def glob(pattern, &block)
    Pathname.glob(self.join(pattern), &block)
  end
end

Slide = Struct.new(:name, :title, :type, :html, :file) do
  def style
    file.dirname.join("#{name}.css.sass")
  end

  def js
    file.dirname.join("#{name}.js.coffee")
  end

  def name
    file.basename.sub_ext('')
  end
end

class Environment
  attr_accessor :slides

  def initialize(production)
    @slides     = []
    @production = production
  end

  def type(value);  @type = value; end
  def name(value);  @name = value; end
  def title(value); @title = value; end

  def render(file, &block)
    @current = file
    Haml::Engine.new(file.read, format: :html5).render(self, &block)
  end

  def find_asset(path, ext = nil)
    [COMMON, VENDOR].map { |i| i.join(path) }.find { |i| i.exist? }
  end

  def include_style(path)
    file = find_asset(path + '.css')
    if file
      file.read
    else
      file = find_asset(path + '.css.sass')
      compile(file) if file
    end
  end

  def include_js(path)
    file = find_asset(path + '.js')
    if file
      file.read
    else
      file = find_asset(path + '.js.coffee')
      compile(file) if file
    end
  end

  def compile(file)
    if file.extname == '.sass'
      sass = file.read
      sass = COMMON.join('_base.sass').read + sass
      Sass::Engine.new(sass, Compass.sass_engine_options).render
    elsif file.extname == '.coffee'
      CoffeeScript.compile(file.read)
    end
  end

  def slide(file)
    @name = @title = @type = @cover = nil
    html = render(file)
    html = image_tag(@cover, class: 'cover') + html if @cover
    @slides << Slide.new(@name, @title, @type, html, file)
  end

  def slides_styles
    slides.map(&:style).reject {|i| !i.exist? }.map {|i| compile(i) }.join("\n")
  end

  def slides_jses
    slides.map(&:js).reject {|i| !i.exist? }.map {|i| compile(i) }.join("\n")
  end

  def image_tag(name, attrs = {})
    attrs[:alt] ||= ''
    attrs = attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
    "<img src=\"#{ @current.dirname.join(name) }\" #{ attrs } />"
  end

  def cover(name)
    @type  = 'cover'
    @cover = name
  end

  def production?
    @production
  end
end

desc 'Build site files'
task :build do |t, args|
  PUBLIC.mkpath
  PUBLIC.glob('*') { |i| i.rmtree }

  print 'build'

  env    = Environment.new(false)
  layout = COMMON.join('layout.html.haml')

  SLIDES.glob('**/*.haml').sort.map { |i| env.slide(i) }
  PUBLIC.join('slideshow.html').open('w') { |io| io << env.render(layout) }

  print "\n"
end

desc 'Rebuild files on every changes'
task :watch do
  Rake::Task['build'].execute

  def rebuild
    print 're'
    Rake::Task['build'].execute
  rescue Exception => e
    puts
    puts "ERROR: #{e.message}"
  end

  require 'fssm'
  FSSM.monitor(ROOT, '{slides,common,vendor}/**/*') do
    update { rebuild }
    delete { rebuild }
    create { rebuild }
  end
end
