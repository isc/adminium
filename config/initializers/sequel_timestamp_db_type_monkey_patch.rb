module Sequel
  class Database
    def schema_column_type(db_type)
      case db_type
      when /\A(character( varying)?|n?(var)?char|n?text|string|clob)/io
        :string
      when /\A(int(eger)?|(big|small|tiny)int)/io
        :integer
      when /\Adate\z/io
        :date
      # Modification on line below to match "(6)" after "timestamp"
      when /\A((small)?datetime|timestamp(\(6\))?( with(out)? time zone)?)(\(\d+\))?\z/io
        :datetime
      when /\Atime( with(out)? time zone)?\z/io
        :time
      when /\A(bool(ean)?)\z/io
        :boolean
      when /\A(real|float( unsigned)?|double( precision)?|double\(\d+,\d+\)( unsigned)?)\z/io
        :float
      when /\A(?:(?:(?:num(?:ber|eric)?|decimal)(?:\(\d+,\s*(\d+|false|true)\))?))\z/io
        $1 && ['0', 'false'].include?($1) ? :integer : :decimal
      when /bytea|blob|image|(var)?binary/io
        :blob
      when /\Aenum/io
        :enum
      end
    end
  end
end
