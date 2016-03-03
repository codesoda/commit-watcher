require_relative "#{Rails.root}/lib/rules/expression_rule"

class Rules < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:name, :rule_type_id, :value]

    validates_unique :name
    validates_min_length 3, :name, message: -> (s) { "must be more than #{s} characters" }
    validates_format /[A-Za-z0-9\-\._]+/,
        :name,
        message: 'invalid name; can include letters, numbers, and "-", ".", "_"'

    validates_includes RuleTypes.keys, :rule_type_id

    expression_id = RuleTypes.select { |_, v| v[:name] == 'expression' }.keys.first
    if rule_type_id == expression_id
      dummy = value.gsub(/[A-Za-z0-9\-\._]+/, 'true')
      begin
        Boolean.parse(dummy)
      rescue Citrus::ParseError => e
        errors.add(:value, "invalid boolean expression #{value}")
      end

      exp = ExpressionRule.new(value)
      exp.rule_names.each do |exp_rule_name|
        next if Rules[name: exp_rule_name]
        errors.add(:value, "referenced rule #{exp_rule_name} does not exist")
      end
    else
      begin
        Regexp.new(value)
      rescue RegexpError => e
        errors.add(:value, "invalid value pattern: #{e}")
      end
    end
  end
end
