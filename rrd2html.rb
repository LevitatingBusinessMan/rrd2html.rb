#!/usr/bin/env ruby
require 'tomlrb'
require 'base64'
$conf = Tomlrb.load_file ARGV[0] || "/etc/rrd2html.toml", symbolize_keys: true

$genline = ->(l, i) {"\
DEF:d#{i}=#{File.join($conf[:datadir], l[:file])}:#{l[:val] || $conf[:val] || 'value:AVERAGE'} \
#{"CDEF:d#{i}i=d#{i},-1,*" if l[:inv]} \
LINE:d#{i}#{"i" if l[:inv]}#{l[:color] || $conf[:color] || '#FF0000'}:#{l[:name].inspect} \
"}

def render graph
    Base64.encode64`
        rrdtool graph - \
        --start=end-#{graph[:span] || $conf[:span] || "1h"} \
        --end=now \
        #{"--title=#{graph[:title].inspect}" if graph[:title]} \
        #{graph[:lines].each_with_index.map(&$genline).join(" ")} \
        --width=#{(graph[:dimensions] || $conf[:dimensions] || [300,100]).join ' --height='}} \
    `
end

puts $conf[:graphs].map { |graph| "<img src=\"data:image;base64,#{render graph}\"/>" }
