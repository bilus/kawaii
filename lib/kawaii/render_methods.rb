module Kawaii
  # Template rendering based on Tilt.
  module RenderMethods
    # Renders a template.
    # @param tmpl [String] file name or path to template, relative to /views in
    #        project dir
    # @example Rendering html erb file
    #   render('index.html.erb')
    # @todo Layouts.
    def render(tmpl)
      t = Tilt.new(File.join('views', tmpl)) # @todo Caching!
      t.render(self)
    end
  end
end
