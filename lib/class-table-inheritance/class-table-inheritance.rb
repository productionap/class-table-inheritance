# ClassTableInheritance is an ActiveRecord plugin designed to allow
# simple multiple table (class) inheritance.
module ClassTableInheritance
  ENSURE_SUBTYPE_INSERTED = true
  module Inheritance
    extend ActiveSupport::Concern
    
    included do
      # TODO: remove this if necessary
      #   there's no other references mentioning this.
      attr_reader :reflection
      
      class_attribute :class_inheritance_column, instance_accessor: false, default: 'subtype'
      singleton_class.class_eval do
        alias_method :_class_inheritance_column=, :class_inheritance_column=
        private :_class_inheritance_column=
        alias_method :class_inheritance_column=, :real_class_inheritance_column=
      end
    end
    
    module Finder
      def find(*args)
        sclass = super
        
        obtain_proper_class = proc do |item|
          item_type = item[class_inheritance_column]
          next sclass if item_type.nil? || item_type.blank?
          item_class = find_cti_class(item.attributes[class_inheritance_column])
          item_class.find(item.id)
        end
        
        begin
          if sclass.kind_of? Array then
            sclass.map(&obtain_proper_class)
          else
            obtain_proper_class.call(sclass)
          end
        rescue
          sclass
        end
      end
    end
    private_constant :Finder
    
    
    module ClassMethods
      def real_class_inheritance_column=(value)
        self._class_inheritance_column = value.to_s
      end
      
      def acts_as_superclass
        return unless self.column_names.include?(class_inheritance_column)
        include Finder
      end
      
      def using_class_table_inheritance?(record)
        record[class_inheritance_column].present? && _has_attribute?(class_inheritance_column)
      end
      
      def cti_class_for(type_name)
        compute_type(type_name)
      end
      
      def find_cti_class(type_name)
        type_name = base_class.type_for_attribute(class_inheritance_column).cast(type_name)
        subclass = cti_class_for(type_name)
        
        return self if subclass == self
        subclass
      end
      
      def cti_name
        name.underscore.gsub(?/, ?_)
      end
      
      def inherits_from(association_name, **options)
        # support old syntax.
        if association_name.kind_of?(String) then
          options[:class_name] = association_name
          association_name = association_name.underscore.gsub(?/, ?_).to_sym
        end
        
        # add an association
        belongs_to association_name, dependent: :destroy, **options
        
        association_refl  = reflections[association_name.to_s]
        # set the primary key, it' need because the generalized table doesn't have
        # a field ID.
        if options.fetch(:foreign_key, nil).present? then
          self.primary_key = options[:foreign_key]
        elsif options.fetch(:follow_primary_key, true) then
          self.primary_key = association_refl.foreign_key
        end
        
        # Autobuild method to make an instance of association
        m = Module.new
        const_set "#{association_name.to_s.camelize}Builder", m
        m.send :define_method, association_name do
          (
            super() ||
            send(
              "build_#{association_name}",
              {association_refl.klass.class_inheritance_column => self.class.cti_name}
            )
          )
        end
        prepend(m)
        
        # bind the before save, this method call the save of association, and
        # get our generated ID an set to association_id field.
        before_save :save_inherit
        
        # Bind the validation of association.
        validate :inherit_association_must_be_valid
        
        # Generate a method to validate the field of association.
        define_method "inherit_association_must_be_valid" do
          association = send(association_name)
          
          unless valid = association.valid?
            association.errors.each do |attr, message|
              errors.add(attr, message)
            end
          end
          
          valid
        end
        
        # get the class of association by reflection, this is needed because
        # i need to get the methods and attributes to make a proxy methods.
        association_class = association_refl.klass
        # Get the colluns of association class.
        inherited_columns = association_class.column_names
        # Make a filter in association colluns to exclude the colluns that
        # the generalized class already have.
        inherited_columns.reject! do |c|
          self.column_names.grep(c).length > 0 ||
          c == inheritance_column ||
          c == class_inheritance_column
        end
        # Get the methods of the association class and tun it to an Array of Strings.
        inherited_methods = association_class.reflections.map { |key,value| key.to_s }
        # Make a filter in association methods to exclude the methods that
        # the generalized class already have.
        inherited_methods.reject! do |c|
          self.reflections.key?(c.to_s)
        end
        # create the proxy methods to get and set the properties and methods
        # in association class.
        (inherited_columns | inherited_methods).each do |meth|
          # for ID field, let the class know what is their primary key.
          # may be adjusted if the primary key itself is not id.
          if name == 'id' then
            define_method meth do
              self[association_refl.foreign_key]
            end
            
            define_method "#{meth}=" do |value|
              self[association_refl.foreign_key] = new_value
            end
          else
            delegate meth, "#{meth}=", to: association_name
          end
        end
        
        # Create a method do bind in before_save callback, this method
        # only call the save of association class and set the id in the
        # generalized class.
        define_method :save_inherit do |*args|
          klass = self.class
          association = send(association_name)
          cn = association_class.class_inheritance_column
          if association.attribute_names.include?(cn) then
            if ENSURE_SUBTYPE_INSERTED then
              association.class.tap do |c|
                c.connection.exec_update(
                  sprintf("UPDATE `%s` SET %s = ? WHERE %s = ?", c.table_name, cn, c.primary_key),
                  nil,
                  [[nil, klass.cti_name], [nil, association.id]]
                )
              end
            else
              association.reload
              association.update!({cn => klass.cti_name})
            end
          end
          # association.save
          _write_attribute(association_refl.foreign_key, association.id)
          true
        end
      end
    end
  end
end

class ActiveRecord::Base
  include ClassTableInheritance::Inheritance
end
