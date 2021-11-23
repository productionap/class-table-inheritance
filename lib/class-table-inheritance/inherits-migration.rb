module ClassTableInheritance
  module InheritsMigration
    # Generate the association field.
    def create_table(table_name, **options, &block)
      $stdout.puts "I SUPPORT INHERITS"
      if options[:inherits] then
        options[:id] ||= false
        
        case options[:inherits]
        when Hash
          table_base       = options[:inherits].fetch(:base).to_s
          column_to_create = options[:inherits].fetch(:primary, nil)
          association_type = options[:inherits].fetch(:model, nil)
        when String, Symbol
          # Let the implementation (automatically) determines from the string you supplied.
          table_base = options[:inherits].to_s
          column_to_create = nil
          association_type = nil
        else
          fail TypeError, "Expected :inherits option to have String, Symbol or Hash."
        end
        
        column_to_create = table_base.underscore.gsub(?/, ?_).downcase if column_to_create.nil?
        association_type = table_base.classify.constantize if association_type.nil?
        primary_key_name = column_to_create.blank? ? "id" : "#{column_to_create}_id"
        
        options[:primary_key] = primary_key
      end
      
      super(table_name, **options) do |table_defintion|
        if options[:inherits] then
          association_inst = association_type.send(:new)
          attr_column = association_inst.column_for_attribute(association_type.primary_key)
          
          field_option = {:primary_key => true, :null => false}
          field_option[:limit] = attr_column.limit if attr_column.limit
          table_defintion.add_column primary_key_name, attr_column.type, field_option
        end
        yield table_defintion
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::SchemaStatements.prepend(ClassTableInheritance::InheritsMigration)
