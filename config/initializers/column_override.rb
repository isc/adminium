class ActiveRecord::ConnectionAdapters::Column
  
  def possible_enum_column
    !primary && ![:date, :datetime, :text, :float].include?(type)
  end
  
  def possible_serializable_column
    [:text, :string].include? type
  end
  
end