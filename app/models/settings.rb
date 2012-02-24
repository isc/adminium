module Settings

  def settings
    @settings ||= Base.new(self)
    return @settings
  end

  class Base

    DEFAULT_PER_PAGE = 25

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

    def per_page= per_page
      @per_page = per_page.to_i
    end

    def per_page
      @per_page ||= DEFAULT_PER_PAGE
    end

    def column_names
      @columns.map do |column|
        column['name']
      end
    end


  end

end