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

activate :syntax
activate :directory_indexes
#activate :relative_assets

#activate :livereload, js_host: 'stage.don.to', port: 4567, no_swf: true
#activate :livereload
