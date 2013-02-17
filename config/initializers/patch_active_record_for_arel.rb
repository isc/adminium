module ActiveRecord
  module SpawnMethods

    def merge(r)
      return self unless r
      return to_a & r if r.is_a?(Array)

      merged_relation = clone

      r = r.with_default_scope if r.default_scoped? && r.klass != klass

      Relation::ASSOCIATION_METHODS.each do |method|
        value = r.send(:"#{method}_values")

        unless value.empty?
          if method == :includes
            merged_relation = merged_relation.includes(value)
          else
            merged_relation.send(:"#{method}_values=", value)
          end
        end
      end

      (Relation::MULTI_VALUE_METHODS - [:joins, :where, :order]).each do |method|
        value = r.send(:"#{method}_values")
        merged_relation.send(:"#{method}_values=", merged_relation.send(:"#{method}_values") + value) if value.present?
      end

      merged_relation.joins_values += r.joins_values

      merged_wheres = @where_values + r.where_values

      unless @where_values.empty?
        # Remove duplicates, last one wins.
        seen = Hash.new { |h,table| h[table] = {} }
        merged_wheres = merged_wheres.reverse.reject { |w|
          nuke = false
          #### PATCH HERE (&& w.left.respond_to?(:relation)) ####
          if w.respond_to?(:operator) && w.operator == :== && w.left.respond_to?(:relation)
            name              = w.left.name
            table             = w.left.relation.name
            nuke              = seen[table][name]
            seen[table][name] = true
          end
          nuke
        }.reverse
      end

      merged_relation.where_values = merged_wheres

      (Relation::SINGLE_VALUE_METHODS - [:lock, :create_with, :reordering]).each do |method|
        value = r.send(:"#{method}_value")
        merged_relation.send(:"#{method}_value=", value) unless value.nil?
      end

      merged_relation.lock_value = r.lock_value unless merged_relation.lock_value

      merged_relation = merged_relation.create_with(r.create_with_value) unless r.create_with_value.empty?

      if (r.reordering_value)
        # override any order specified in the original relation
        merged_relation.reordering_value = true
        merged_relation.order_values = r.order_values
      else
        # merge in order_values from r
        merged_relation.order_values += r.order_values
      end

      # Apply scope extension modules
      merged_relation.send :apply_modules, r.extensions

      merged_relation
    end

  end
end
