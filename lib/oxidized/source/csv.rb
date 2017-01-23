module Oxidized
class CSV < Source
  def initialize
    @cfg = Oxidized.config.source.csv
    super
  end

  def setup
    if @cfg.empty?
      Oxidized.asetus.user.source.csv.file      = File.join(Config::Root, 'router.db')
      Oxidized.asetus.user.source.csv.delimiter = /:/
      Oxidized.asetus.user.source.csv.map.name  = 0
      Oxidized.asetus.user.source.csv.map.model = 1
      Oxidized.asetus.user.source.csv.gpg       = false
      Oxidized.asetus.save :user
      raise NoConfig, 'no source csv config, edit ~/.config/oxidized/config'
    end
  end

  def load
    nodes = []
    if @cfg.gpg != 'false'
      crypto = GPGME::Crypto.new :password => @cfg.gpg_password
      file   = crypto.decrypt(File.open(@cfg.file)).to_s
    else
      file = open(File.expand_path @cfg.file)
    end
    file.each_line do |line|
      next if line.match(/^\s*#/)
      data  = line.chomp.split(@cfg.delimiter, -1)
      next if data.empty?
      # map node parameters
      keys = {}
      @cfg.map.each do |key, position|
        keys[key.to_sym] = node_var_interpolate data[position]
      end
      keys[:model] = map_model keys[:model] if keys.key? :model

      # map node specific vars
      vars = {}
      @cfg.vars_map.each do |key, position|
        vars[key.to_sym] = node_var_interpolate data[position]
      end
      keys[:vars] = vars unless vars.empty?

      nodes << keys
    end
    nodes
  end

end
end
