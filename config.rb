###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true,
               :autolink => true,
               :smartypants => true

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
#page "/presentation/slides/*.html", :layout => :remark
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }
for y in data.year.thisyear.downto(1995) do
  proxy "/diary/#{y}.html", "/diary/yearly.html", :locals => { :year => y }, :ignore => true
end

###
# Helpers
###
require "lib/link_helpers"
helpers LinkHelpers

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'
set :slim, { :pretty => true, :sort_attrs => false, :format => :html }

activate :sprockets

activate :syntax
activate :directory_indexes
#activate :relative_assets

activate :asset_hash

#activate :livereload, js_host: 'stage.aws.don.to', port: 8888, no_swf: true
#activate :livereload
# Build-specific configuration
configure :build do
  activate :minify_css
  activate :minify_javascript
  #activate :asset_hash

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end

