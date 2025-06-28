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
    pier/iss
  ],
}

PAK_DIRS_HASH = PAK_DIRS.map{|size, dirs| dirs.map{|dir| [dir, size]} }.flatten(1).to_h

THREAD_COUNT = 6 # GitHub ActionsのThread数が4らしいので、おまけして6スレッドにした

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
      when 'copy'
        copy()
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
    copy()
    version()
  end

  # makedatを実行
  def makedat
    makedat = MakeDat.new
    Dir.glob('**/*.datt').each do |file|
      dat_file = file.sub(/\.datt$/, '.dat')
      # 依存ファイルを取得し、datファイルよりも新しいものがあれば再生成する
      dependencies = makedat_dependencies(file)
      dat_mtime = File.exist?(dat_file) ? File.mtime(dat_file) : Time.at(0) # datファイルが存在しない場合は1970年1月1日を基準とする
      next if dependencies.all? { |dep| File.exist?(dep) && File.mtime(dep) <= dat_mtime }
      puts "Creating dat file for #{file}"
      makedat.create_dat(file)
    end
  end

  # datファイルの依存関係を取得する
  # %requireや%require_excelで指定されたファイルを再帰的に取得する
  def makedat_dependencies(datt_file)
    dependencies = [datt_file]
    File.open(datt_file, 'r') do |file|
      file.each_line do |line|
        if line =~ /^%require\s+['"](.*)['"]/
          require_file = File.expand_path($1, File.dirname(datt_file))
          dependencies += makedat_dependencies(require_file)
        elsif line =~ /^%require_excel\s+['"](.*)['"]/
          require_file = File.expand_path($1, File.dirname(datt_file))
          dependencies << require_file
        end
      end
    end
    dependencies.uniq
  end

  # makeobjを実行
  # 出力はPak128.Japan-Ex+Addons/以下に作成する
  def makeobj
    makeobj = Makeobj.new
    FileUtils.mkdir_p('Pak128.Japan-Ex+Addons')
    # 並列処理のためのキューを作成
    queue = Queue.new
    PAK_DIRS_HASH.each do |dir, size|
      Dir.glob("#{dir}/**/*.dat").each do |file|
        pak_file = 'Pak128.Japan-Ex+Addons/' + File.basename(file, '.dat') + '.pak'
        # pakファイルが存在しない、またはdatファイルよりも新しい場合のみ処理する
        dependencies = makeobj_dependencies(file)
        pak_mtime = File.exist?(pak_file) ? File.mtime(pak_file) : Time.at(0) # pakファイルが存在しない場合は1970年1月1日を基準とする
        next if dependencies.all? { |dep| File.exist?(dep) && File.mtime(dep) <= pak_mtime }
        queue << [file, size]
      end
    end

    # 並列処理
    threads = []
    Thread.ignore_deadlock = true
    THREAD_COUNT.times do
      threads << Thread.new do
        loop do
          file, size = queue.pop(true) rescue break
          puts "Processing #{file}"
          output_path = 'Pak128.Japan-Ex+Addons/' + File.basename(file, '.dat') + '.pak'
          makeobj.create_pak(file, size, output_path)
          puts "Created #{output_path}"
        end
      end
    end

    threads.each(&:join)
  end

  # pakファイルの依存関係を取得する
  # 以下の場合、yyy.pngを依存関係として取得する
  # xxx[12][34]=yyy.12.34
  # xxx=> yyy
  def makeobj_dependencies(dat_file)
    dependencies = [dat_file]
    File.open(dat_file, 'r') do |file|
      file.each_line do |line|
        if line =~ /^\w+(\[\w+\])*=(> )?((\.\.\/)*\w+)\.\d+\.\d+/
          require_file = File.expand_path("#{$3}.png", File.dirname(dat_file))
          dependencies << require_file
        end
      end
    end
    dependencies.uniq
  end

  # 必要なファイルをコピー
  def copy
    puts "Copying config files"
    FileUtils.mkdir_p('Pak128.Japan-Ex+Addons/config')
    Dir.glob('config/*').each do |file|
      FileUtils.cp(file, 'Pak128.Japan-Ex+Addons/config/')
    end
    puts "Copying README.md"
    FileUtils.cp('README.md', 'Pak128.Japan-Ex+Addons/README.md')
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
