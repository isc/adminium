UNARY_OPERATOR_DEFINITIONS = {'null' => "_ IS NULL", 'not_null' => "_ IS NOT NULL"}
UNARY_OPERATORS = UNARY_OPERATOR_DEFINITIONS.keys
INTEGER_OPERATORS = ['=', '>=', '<=', '>', '<', '!=', 'IN']
UNARY_DATETIME_OPERATORS = ['today', 'yesterday', 'this_week', 'last_week']
DATETIME_OPERATORS = ['on', 'before', 'after', 'not'] + UNARY_DATETIME_OPERATORS
BOOLEAN_OPERATORS = ['is_true', 'is_false']

STRING_LIKE_OPERATOR_DEFINITIONS = {'like' => '%_%', 'starts_with' => '_%', 'ends_with' => '%_', 'is' => '_'}
STRING_OPERATOR_DEFINITIONS  = {'blank' => "_ IS NULL OR _ = ''", 'present' => "_ IS NOT NULL AND _ != ''"}