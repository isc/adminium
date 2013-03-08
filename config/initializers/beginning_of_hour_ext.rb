class DateTime
  def beginning_of_hour
    change(:min => 0, :sec => 0)
  end
  
  def beginning_of_minute
    change(:sec => 0)
  end
end

class Time
  def beginning_of_hour
    change(:min => 0, :sec => 0)
  end
  
  def beginning_of_minute
    change(:sec => 0)
  end
end
