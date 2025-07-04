# 正規分布の累積分布関数（CDF）を計算する関数
def normal_cdf(x, mean, sigma)
  # 標準化
  z = (x - mean) / sigma.to_f
  
  # 標準正規分布の累積分布関数を計算
  # erf関数を使用してΦ(z) = 0.5 * (1 + erf(z/√2))
  0.5 * (1 + Math.erf(z / Math.sqrt(2)))
end

# 指定された区間の確率を計算する関数
def class_probs(mean, sigma)
  # 区間の境界値
  boundaries = [-Float::INFINITY, 0.5, 1.5, 2.5, 3.5, 4.5, Float::INFINITY]
  
  probabilities = []
  
  # 各区間の確率を計算
  (0...6).each do |i|
    lower = boundaries[i]
    upper = boundaries[i + 1]
    
    # 区間の確率 = P(lower ≤ X < upper) = CDF(upper) - CDF(lower)
    if lower == -Float::INFINITY
      prob = normal_cdf(upper, mean, sigma)
    elsif upper == Float::INFINITY
      prob = 1.0 - normal_cdf(lower, mean, sigma)
    else
      prob = normal_cdf(upper, mean, sigma) - normal_cdf(lower, mean, sigma)
    end
    
    probabilities << prob
  end
  
  probabilities
end

# 以下はテスト用

# 結果を百分率で出力する関数
def print_results(mean, sigma)
  probabilities = class_probs(mean, sigma)
  
  puts "平均値: #{mean}, 標準偏差: #{sigma}"
  puts "区間別確率（百分率）:"
  
  intervals = [
    "(-∞, 0.5)",
    "[0.5, 1.5)",
    "[1.5, 2.5)",
    "[2.5, 3.5)",
    "[3.5, 4.5)",
    "[4.5, +∞)"
  ]
  
  probabilities.each_with_index do |prob, i|
    percentage = (prob * 100).round(2)
    puts "#{i}: #{intervals[i]} => #{percentage}%"
  end
  
  # 合計が100%になることを確認
  total = probabilities.sum * 100
  puts "合計: #{total.round(2)}%"
end

# 使用例
if __FILE__ == $0
  puts "=== 例1: 平均2.5, 標準偏差1.0 ==="
  print_results(2.5, 1.0)
  
  puts "\n=== 例2: 平均1.0, 標準偏差0.5 ==="
  print_results(1.0, 0.5)
  
  puts "\n=== 例3: 平均3.0, 標準偏差2.0 ==="
  print_results(3.0, 2.0)
end
