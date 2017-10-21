UNARY_OPERATOR_DEFINITIONS = {'null' => '_ IS NULL', 'not_null' => '_ IS NOT NULL'}.freeze
UNARY_OPERATORS = UNARY_OPERATOR_DEFINITIONS.keys
INTEGER_OPERATORS = ['=', '>=', '<=', '>', '<', '!=', 'IN'].freeze
UNARY_DATETIME_OPERATORS = %w(today yesterday this_week last_week).freeze
DATETIME_OPERATORS = %w(on before after not) + UNARY_DATETIME_OPERATORS
BOOLEAN_OPERATORS = %w(is_true is_false).freeze

STRING_LIKE_OPERATOR_DEFINITIONS = {'like' => '%_%', 'starts_with' => '_%', 'ends_with' => '%_', 'is' => '_'}.freeze
STRING_OPERATOR_DEFINITIONS = {'blank' => "_ IS NULL OR _ = ''", 'present' => "_ IS NOT NULL AND _ != ''"}.freeze
