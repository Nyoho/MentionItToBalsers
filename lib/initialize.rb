APPLICATION_ROOT = File.absolute_path(File.join(File.dirname(__FILE__),".."))
# puts "Application Root: %s" % APPLICATION_ROOT
$: << APPLICATION_ROOT

require 'lib/util'
