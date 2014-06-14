require 'rbvmomi'
require 'awesome_print'
require 'trollop'
require 'rbvmomi/trollop'

opts = Trollop.options do
  banner <<-EOS
Script to list VMWare snaps.

Usage:
    list_snaps.rb [options]

VIM connection options:
    EOS

    rbvmomi_connection_opts

    text <<-EOS

VM location options:
    EOS

    rbvmomi_datacenter_opt

    text <<-EOS

Other options:
  EOS

  opt :one, "Output on one line for easier greps"
end

Trollop.die("must specify host") unless opts[:host]

def folder?(obj)
  if obj.respond_to?(:children)
    true
  else
    false
  end
end

def snap_list(obj)
  snaps = Array.new
  if obj.childSnapshotList.nil?
    nil
  else
    obj.childSnapshotList.each do |s|
      snaps << s
      snaps.concat snap_list(s) unless s.childSnapshotList.nil?
    end
  end
  snaps
end

vim = RbVmomi::VIM.connect opts
dc = vim.serviceInstance.find_datacenter(opts[:datacenter]) or fail "datacenter not found"

dc.vmFolder.inventory_flat({ :VirtualMachine => :all, :Folder => :all }).each do |v,i|
  unless folder?(v)
    unless v.snapshot.nil?
      puts "#{v.name}:" unless opts[:one]
      v.snapshot.rootSnapshotList.each do |s|
        snap_name = s.name.to_s
        snap_time = s.createTime.localtime.to_s
        if opts[:one]
          puts "#{v.name}:\t#{snap_time}\t#{snap_name}"
        else
          puts "\t#{snap_time}\t#{snap_name}"
        end
        
        snap_list(s).each do |i|
          if opts[:one]
            puts "#{v.name}:\t#{i.createTime.localtime.to_s}\t#{i.name}"
          else
            puts "\t#{i.createTime.localtime.to_s}\t#{i.name}"
          end
        end
      end
    end
  end
end