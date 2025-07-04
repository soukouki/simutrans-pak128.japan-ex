def set_WM(working_method)
    case working_method
    when '無閉塞運転'
        'drive_by_sight'
    when '時間間隔式'
        'time_interval'
    when '電信時間間隔式'
        'time_interval_with_telegraph'
    when 'スタフ閉塞'
        'one_train_staff'
    when 'タブレット閉塞'
        'token_block'
    when '双信閉塞'
        'absolute_block'
    when '自動閉塞'
        'track_circuit_block'
    when '車内信号式'
        'cab_signalling'
    when '移動閉塞'
        'moving_block'
    else
        'track_circuit_block'
    end
end