#!/usr/bin/env ruby

HELP_MESSAGE = <<~EOS
ruby scripts/make.rb <command>

COMMAND:
all: paksetを作成 create pakset
clean: 作成したファイルを削除 clean up created files
help: このヘルプを表示 display this help
EOS

PAK64_DIRS = %w[
  gui64-test
  menu
  symbol
]

PAK128_DIRS = %w[
  cursor
  goods
  ground
  ways
  misc
]

PAK_DIRS = (PAK64_DIRS.map{|d|[d, 64]} + PAK128_DIRS.map{|d|[d, 128]}).to_h

require 'fileutils'

require_relative 'makedat'
require_relative 'makeobj'

class Make
  def run(args)
    loop do
      case args.shift
      when 'all'
        all()
      when 'makedat'
        makedat()
      when 'makeobj'
        makeobj()
      when 'copy_config'
        copy_config()
      when 'clean'
        clean()
      when 'help', nil
        help()
      else
        puts "Unknown command: #{args.first}"
        help
        break
      end
      break if args.empty?
    end
  end

  def help
    puts HELP_MESSAGE
  end

  def all
    makedat()
    makeobj()
    copy_config()
  end

  def makedat
    # makedatを実行
    makedat = MakeDat.new
    Dir.glob('**/*.datt').each do |file|
      puts "Processing #{file}"
      makedat.create_dat(file)
    end
  end

  def makeobj
    # makeobjを実行
    # 出力はPak128.Japan-Ex+Addons/以下に作成する
    makeobj = Makeobj.new
    FileUtils.mkdir_p('Pak128.Japan-Ex+Addons')
    PAK_DIRS.each do |dir, size|
      Dir.glob("#{dir}/**/*.dat").each do |file|
        puts "Processing #{file}"
        output_path = 'Pak128.Japan-Ex+Addons/' + File.basename(file, '.dat') + '.pak'
        makeobj.create_pak(file, size, output_path)
      end
    end
  end

  def copy_config
    # config以下のファイルをPak128.Japan-Ex+Addons/config/にコピー
    puts "Copying config files"
    FileUtils.mkdir_p('Pak128.Japan-Ex+Addons/config')
    Dir.glob('config/*').each do |file|
      FileUtils.cp(file, 'Pak128.Japan-Ex+Addons/config/')
    end
  end

  def clean
    puts "Cleaning up created files..."
    # datファイルは同名のdattファイルがある場合のみ削除する
    Dir.glob('**/*.dat').each do |file|
      datt_file = file.sub(/\.dat$/, '.datt')
      FileUtils.rm(file) if File.exist?(datt_file)
    end
    FileUtils.rm_rf(Dir.glob('**/*.pak'))
    FileUtils.rm_rf('Pak128.Japan-Ex+Addons')
    puts "Cleanup complete."
  end
end

make = Make.new
make.run(ARGV)
