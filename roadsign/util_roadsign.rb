def set_WM(working_method)
    case working_method
    when '無閉塞運転'
        return 'drive_by_sight'
    when '時間間隔式'
        return 'time_interval'
    when '電信時間間隔式'
        return 'time_interval_with_telegraph'
    when 'スタフ閉塞'
        return 'one_train_staff'
    when 'タブレット閉塞'
        return 'token_block'
    when '双信閉塞'
        return 'absolute_block'
    when '自動閉塞'
        return 'track_circuit_block'
    when '車内信号式'
        return 'cab_signalling'
    when '移動閉塞'
        return 'moving_block'
    else
        return 'track_circuit_block'
    end
end