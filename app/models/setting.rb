class Setting < ApplicationModel
  store         :options
  store         :state
  store         :state_initial
  before_create :state_check, :set_initial
  before_update :state_check
  after_create  :delete_cache
  after_update  :delete_cache

  def self.load

    # check if config is already generated
    return Thread.current[:settings_config] if Thread.current[:settings_config]

    # read all config settings
    config = {}
    Setting.select('name, state').order(:id).each { |setting|
      config[setting.name] = setting.state[:value]
    }

    # config lookups
    config.each { |key, value|
      next if value.class.to_s != 'String'
      config[key].gsub!( /\#\{config\.(.+?)\}/ ) { |s|
        s = config[$1].to_s
      }
    }

    # store for class requests
    Thread.current[:settings_config] = config
    return config
  end

  def self.set(name, value)
    setting = Setting.where( :name => name ).first
    if !setting
      raise "Can't find config setting '#{name}'"
    end
    setting.state = { :value => value }
    setting.save
  end

  def self.get(name)
    self.load
    return Thread.current[:settings_config][name]
  end

  private
    def delete_cache
      Thread.current[:settings_config] = nil
    end
    def set_initial
      self.state_initial = self.state
    end
    def state_check
      if self.state
        if !self.state.has_key?(:value)
          self.state = { :value => self.state }
        end
      end
    end
end
