=begin
  requireの失敗を握りつぶす
=end
def require(path)
  super
rescue Exception => e
  $stderr.puts "failed to load #{path}"
end
