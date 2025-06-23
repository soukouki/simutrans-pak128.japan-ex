
require_relative 'datt'

class MakeDat
  def create_dat(datt_file, dat_file = nil)
    dat_file ||= datt_file.sub(/\.datt$/, '.dat')

    wk = Datt::Workspace.new
    # datt.rbはputsを利用して$stdoutに出力するため、$stdoutを一時的に変更する。

    open(dat_file, 'w') do |output|
      begin
        original_stdout = $stdout # 元の$stdoutを保存
        $stdout = output
        open(datt_file, 'r') do |input|
          wk.eval_datt(input, datt_file, nil)
        end
      ensure # 必ず$stdoutを元に戻すためにensureを使う
        $stdout = original_stdout
      end
    end
  end
end
