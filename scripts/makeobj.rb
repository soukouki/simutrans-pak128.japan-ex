
require 'rbconfig'

class Makeobj

  def initialize
    host_os = RbConfig::CONFIG['host_os']
    @os =
    if host_os =~ /linux/
      :linux
    elsif host_os =~ /mswin|mingw|cygwin/
      :windows
    else
      throw <<~EOS
        "#{host_os}" is not supported.
        Please use Linux or Windows.

        "#{host_os}"はサポートされていません。
        LinuxまたはWindowsを使用してください。

        MacOSはMakeobj-Extendedを入手できないため、現在サポートしていません。もしMacOS版のMakeobj-Extendedが用意できる場合はご連絡ください。
      EOS
    end
    puts "Detected: #{@os} (#{RbConfig::CONFIG['platform']})"

    @makeobj_path = {
      linux: "makeobj/makeobj-extended",
      windows: "makeobj/Makeobj-Extended.exe"
    }[@os]
  end

  def create_pak(dat_file, size, pak_file = nil)
    pak_file ||= dat_file.sub(/\.dat$/, '.pak')

    IO.popen([@makeobj_path, "pak#{size}", pak_file, dat_file], err: [:child, :out]) do |io|
      io.each_line do |line|
        # 出力が多いので、特定のプレフィックスを持つ行は表示しない
        calm_prefix = [
          'Writing file ',
          '   Reading file ',
          '      packing ',
        ]
        puts line.chomp if calm_prefix.all?{|prefix| !line.start_with?(prefix) }
      end
    end
  end
end
