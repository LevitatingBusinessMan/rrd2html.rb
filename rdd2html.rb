require "tomlrb"
require 'base64'
$conf = Tomlrb.load_file ARGV[0] || "rdd2html.toml", symbolize_keys: true

def file datafile
    File.join($conf[:datadir], datafile)
end

$genline = ->(l, i) {"DEF:d#{i}=#{File.join($conf[:datadir], l[:file])}:#{l[:val] || $conf[:val] || 'value:AVERAGE'} \
LINE#{i+1}:d#{i}#{l[:color] || $conf[:color] || '#FF0000'}:#{l[:name].inspect}"}

def render graph
    `
        rrdtool graph - \
        --start=end-#{graph[:span] || $conf[:span] || "1h"} \
        --end=now \
        #{graph[:title] ? "--title=#{graph[:title].inspect}" : ''} \
        #{graph[:lines].each_with_index.map(&$genline).join(" ")} \
        --width=#{(graph[:dimensions] || $conf[:dimensions] || [300,100]).join ' --height='}} \
        | base64 -w0
    `
end

puts $conf[:graphs].map { |graph| "<img src=\"data:image;base64,#{render graph}\"/><br/>"}
