#!/usr/bin/env ruby

HELP_MESSAGE = <<~EOS
ruby scripts/make.rb <command>

COMMAND:
all: paksetを作成 create pakset
clean: 作成したファイルを削除 clean up created files
help: このヘルプを表示 display this help
EOS

PAK_DIRS = {
  64 => %w[
    gui64-test
    menu
    symbol
  ],
  128 => %w[
    cursor
    goods
    ground
    ways/128britain-ex
    misc
  ],
  256 => %w[
    ways/iss
  ],
}

PAK_DIRS_HASH = PAK_DIRS.map{|size, dirs| dirs.map{|dir| [dir, size]} }.flatten(1).to_h

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
      when 'version'
        version()
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
    version()
  end

  # makedatを実行
  def makedat
    makedat = MakeDat.new
    Dir.glob('**/*.datt').each do |file|
      puts "Processing #{file}"
      makedat.create_dat(file)
    end
  end

  # makeobjを実行
  # 出力はPak128.Japan-Ex+Addons/以下に作成する
  def makeobj
    makeobj = Makeobj.new
    FileUtils.mkdir_p('Pak128.Japan-Ex+Addons')
    PAK_DIRS_HASH.each do |dir, size|
      Dir.glob("#{dir}/**/*.dat").each do |file|
        puts "Processing #{file}"
        output_path = 'Pak128.Japan-Ex+Addons/' + File.basename(file, '.dat') + '.pak'
        makeobj.create_pak(file, size, output_path)
      end
    end
  end

  # config以下のファイルをPak128.Japan-Ex+Addons/config/にコピー
  def copy_config
    puts "Copying config files"
    FileUtils.mkdir_p('Pak128.Japan-Ex+Addons/config')
    Dir.glob('config/*').each do |file|
      FileUtils.cp(file, 'Pak128.Japan-Ex+Addons/config/')
    end
  end

  # 環境変数VERSIONを見て、Pak128.Japan-Ex+Addons/version.txtを作成する
  # もしVERSIONが設定されていなければ、"dev"を指定する
  def version
    version = ENV['VERSION'] || 'dev'
    puts "Creating version file with version: #{version}"
    FileUtils.mkdir_p('Pak128.Japan-Ex+Addons')
    File.open('Pak128.Japan-Ex+Addons/version.txt', 'w') do |file|
      file.puts <<~EOS
        #{version}

        バージョンの説明:
        v1.2.3 : リリースバージョン
        n123   : 開発中のバージョン(CDによるビルド)
        dev    : 開発中のバージョン(ローカルビルド)

        Version Description:
        v1.2.3 : Released version
        n123   : Development version (built via CD)
        dev    : Development version (local build)
      EOS
    end
  end

  def clean
    puts "Cleaning up created files..."
    # datファイルは同名のdattファイルがある場合のみ削除する
    # .dattファイルが無い場合、警告メッセージを出力する
    Dir.glob('**/*.dat').each do |file|
      datt_file = file.sub(/\.dat$/, '.datt')
      if File.exist?(datt_file)
        puts "Removing #{file}"
        FileUtils.rm(file)
      else
        puts "Warning: No corresponding .datt file for #{file}, skipping deletion."
      end
    end
    FileUtils.rm_rf(Dir.glob('**/*.pak'))
    FileUtils.rm_rf('Pak128.Japan-Ex+Addons')
    puts "Cleanup complete."
  end
end

make = Make.new
make.run(ARGV)
