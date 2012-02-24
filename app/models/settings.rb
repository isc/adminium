module Settings

  def settings
    @settings ||= Base.new(self)
    return @settings
  end

  class Base

    def initialize(clazz)
      @clazz = clazz
      load
    end

    def load
      value = REDIS.get "#{@clazz.original_name}:settings"
      if value.nil?
        self.columns = @clazz.columns.map(&:name)
      else
        datas = JSON.parse(value).symbolize_keys!
        @columns = datas[:columns]
      end
    end

    def save
      REDIS.set "#{@clazz.original_name}:settings", {:columns => @columns}.to_json
    end

    def columns= columns
      @columns = columns.map do |column|
        {'name' => column}
      end
    end

    def column_names
      @columns.map do |column|
        column['name']
      end
    end


  end

end