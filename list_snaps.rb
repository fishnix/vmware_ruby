require 'rbvmomi'
require 'awesome_print'
require 'trollop'
require 'rbvmomi/trollop'

def folder?(obj)
  if obj.respond_to?(:children)
    true
  else
    false
  end
end

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
end

Trollop.die("must specify host") unless opts[:host]

vim = RbVmomi::VIM.connect opts
dc = vim.serviceInstance.find_datacenter(opts[:datacenter]) or fail "datacenter not found"

dc.vmFolder.inventory_flat({ :VirtualMachine => :all, :Folder => :all }).each do |v,i|
  unless folder?(v)
    unless v.snapshot.nil?
      puts "#{v.name}:"
      v.snapshot.rootSnapshotList.each do |s|
        snap_name = s.name.to_s
        snap_time = s.createTime.localtime.to_s
        puts "\t#{snap_time}\t#{snap_name}"
      end
    end
  end
end