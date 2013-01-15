class ActiveRecord::Reflection::AssociationReflection
  
  def original_name
    name.to_s.gsub '_adminium_', ''
  end
  
  def original_plural_name
    plural_name.to_s.gsub '_adminium_', ''
  end
  
end
