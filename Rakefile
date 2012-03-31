require 'pathname'
require 'base64'
ROOT   = Pathname(__FILE__).dirname
PUBLIC = ROOT.join('public')
SLIDES = ROOT.join('slides')
COMMON = ROOT.join('common')
VENDOR = ROOT.join('vendor')

require 'haml'
require 'compass'
require 'animation'
require 'ceaser-easing'
require 'coffee-script'
require 'uglifier'

Compass.configuration.images_path     = ROOT.to_s
Compass.configuration.fonts_path      = VENDOR.to_s
Compass.configuration.http_fonts_path = 'file:///' + VENDOR.to_s

class Pathname
  def glob(pattern, &block)
    Pathname.glob(self.join(pattern), &block)
  end
end

Slide = Struct.new(:name, :title, :types, :html, :file) do
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

  def initialize(build_type)
    @slides     = []
    @build_type = build_type

    if production?
      Compass.configuration.http_images_path = './'
    else
      Compass.configuration.http_images_path = 'file:///' + ROOT.to_s
    end
  end

  def name(value);  @name = value; end
  def title(value); @title = value; end

  def type(*values)
    @types += ' ' + values.join(' ')
  end

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
      base = COMMON.join('_base.sass').read
      if standalone?
        sass = base + COMMON.join('_standalone.sass').read + file.read
      else
        sass = base + file.read
      end
      opts = Compass.sass_engine_options
      opts[:line_comments] = false
      opts[:style] = :nested
      Sass::Engine.new(sass, opts).render
    elsif file.extname == '.coffee'
      CoffeeScript.compile(file.read)
    end
  end

  def slide(file)
    @name  = @title = @cover = nil
    @types = ''
    html = render(file)
    html = image_tag(@cover, class: 'cover') + html if @cover
    @slides << Slide.new(@name, @title, @types, html, file)
  end

  def slides_styles
    slides.map(&:style).reject {|i| !i.exist? }.map {|i| compile(i) }.join("\n")
  end

  def slides_jses
    slides.map(&:js).reject {|i| !i.exist? }.map {|i| compile(i) }.join("\n")
  end

  def compress_js(&block)
    js = capture_haml(&block)
    if development?
      js
    else
      Uglifier.compile(js, copyright: false)
    end
  end

  def image_tag(name, attrs = {})
    attrs[:alt] ||= ''
    uri  = @current.dirname.join(name)
    type = file_type(uri)
    if type == 'image/gif'
      attrs[:class] = (attrs[:class] ? attrs[:class] + ' ' : '') + 'gif'
    end
    if standalone?
      uri = encode_image(uri, type)
    elsif production?
      uri = uri.to_s.gsub(ROOT.to_s + '/', '')
    end
    attrs = attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
    "<img src=\"#{ uri }\" #{ attrs } />"
  end

  def encode_image(file, type)
    "data:#{type};base64," + Base64.encode64(file.open { |io| io.read })
  end

  def file_type(file)
    `file -ib #{file}`.split(';').first
  end

  def cover(name)
    @types += ' cover'
    @cover  = name
  end

  def standalone?
    @build_type == 'standalone'
  end

  def production?
    @build_type == 'production'
  end

  def development?
    @build_type == 'development'
  end

  def google_fonts
    ['family=PT+Sans&subset=latin,cyrillic',
     'family=PT+Sans+Narrow:700&subset=latin,cyrillic',
     'family=PT+Mono']
  end
end

desc 'Build site files'
task :build do |t, args|
  PUBLIC.mkpath
  PUBLIC.glob('*') { |i| i.rmtree }

  print 'build'

  env    = Environment.new(ENV['build'] || 'development')
  layout = COMMON.join('layout.html.haml')
  name   = 'rit3d.html'
  name   = 'index.html' if env.production?

  SLIDES.glob('**/*.haml').sort.map { |i| env.slide(i) }
  PUBLIC.join(name).open('w') { |io| io << env.render(layout) }

  if env.production?
    ROOT.glob('**/*.{png,gif,jpg}') do |from|
      next if from.to_s.start_with? PUBLIC.to_s
      to = PUBLIC.join(from.relative_path_from(ROOT))
      to.dirname.mkpath
      FileUtils.cp(from, to)
    end
  end

  if env.standalone?
  end

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

desc 'Deploy files to web'
task :deploy do
  Dir.mktmpdir do |tmp_dir|
    tmp = Pathname(tmp_dir)
    %w(standalone production).each do |build|
      ENV['build'] = build
      Rake::Task['build'].execute
      PUBLIC.glob('**/*') do |from|
        next if from.directory?
        to = tmp.join(from.relative_path_from(PUBLIC))
        to.dirname.mkpath
        FileUtils.cp(from, to)
      end
    end

    `git checkout gh-pages`
    ROOT.glob('*') { |i| i.rmtree }
    tmp.glob('**/*') do |from|
      next if from.directory?
      to = ROOT.join(from.relative_path_from(tmp))
      to.dirname.mkpath
      FileUtils.cp(from, to)
    end
  end
end

desc 'Optimize PNGs'
task :png do
  ROOT.glob("**/*.png") do |i|
    sh "pngcrush -rem gAMA -rem cHRM -rem iCCP -rem sRGB #{i} #{i}.optimized"
    FileUtils.rm i
    FileUtils.cp "#{i}.optimized", i
    FileUtils.rm "#{i}.optimized"
  end
end
