require 'bundler/setup'
Bundler.require(:default)

module Types
  class BaseArgument < GraphQL::Schema::Argument
  end
end

module Types
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument
  end
end

module Types
  class BaseObject < GraphQL::Schema::Object
    field_class Types::BaseField
  end
end

module Types
  class LocationType < Types::BaseObject
    field :file, String, null: false
    field :line, Integer, null: false

    def line
      object.line.to_i
    end
  end
end

module Types
  class EntryType < Types::BaseObject
    field :detail_source, String, null: false
    field :encoding, String, null: false
    field :synopsis_source, String, null: false
    field :type_id, String, null: false
  end
end

module Types
  class ClassEntryType < EntryType; end
  class DocEntryType < EntryType; end
  class LibraryEntryType < EntryType; end
  class MethodEntryType < EntryType; end
end

module Types
  class PartsType < Types::BaseObject
    field :singleton_methods, [MethodEntryType], null: false, resolver_method: :resolve_singleton_methods
    field :private_singleton_methods, [MethodEntryType], null: false
    field :instance_methods, [MethodEntryType], null: false
    field :private_instance_methods, [MethodEntryType], null: false
    field :module_functions, [MethodEntryType], null: false
    field :constants, [MethodEntryType], null: false
    field :special_variables, [MethodEntryType], null: false
    field :added, [MethodEntryType], null: false
    field :undefined, [MethodEntryType], null: false

    def resolve_singleton_methods
      object.singleton_methods
    end
  end
end

module Types
  class ClassEntryType < EntryType
    field :id, ID, null: false
    field :name, String, null: false
    field :realname, String, null: false
    field :label, String, null: false
    field :labels, [String], null: false
    field :type, String, null: false
    field :superclass, ClassEntryType, null: false
    field :included, [ClassEntryType], null: false
    field :extended, [ClassEntryType], null: false
    field :dynamically_included, [ClassEntryType], null: false
    field :dynamically_extended, [ClassEntryType], null: false
    field :library, [LibraryEntryType], null: false
    field :aliases, [ClassEntryType], null: false
    field :aliasof, ClassEntryType, null: false
    field :source, String, null: false
    field :source_location, LocationType, null: false
    field :ancestors, [ClassEntryType], null: false
    field :included_modules, [ClassEntryType], null: false
    field :extended_modules, [ClassEntryType], null: false
    field :entries, [MethodEntryType], null: false
    field :methods, [MethodEntryType], null: false, resolver_method: :entries
    field :partitioned_entries, PartsType, null: false
    field :singleton_methods, [MethodEntryType], null: false, resolver_method: :resolve_singleton_methods
    field :public_singleton_methods, [MethodEntryType], null: false
    field :instance_methods, [MethodEntryType], null: false
    field :private_singleton_methods, [MethodEntryType], null: false
    field :public_instance_methods, [MethodEntryType], null: false
    field :private_instance_methods, [MethodEntryType], null: false
    field :private_methods, [MethodEntryType], null: false, resolver_method: :resolve_private_methods
    field :constants, [MethodEntryType], null: false
    field :special_variables, [MethodEntryType], null: false
    field :singleton_method_names, [String], null: false
    field :instance_method_names, [String], null: false
    field :constant_names, [String], null: false
    field :special_variable_names, [String], null: false
    field :description, String, null: false

    def resolve_singleton_methods
      object.singleton_methods
    end
    def resolve_private_methods
      object.private_methods
    end
  end
end

module Types
  class DocEntryType < EntryType
    field :description, String, null: false
    field :id, ID, null: false
    field :name, String, null: false
    field :label, String, null: false
    field :labels, [String], null: false
    field :source, String, null: false
    field :source_location, LocationType, null: false
    field :title, String, null: false

    # field :classes, [ClassEntryType], null: false
    # field :error_classes, [ClassEntryType], null: false
    # field :methods, [MethodEntryType], null: false
    # field :libraries, [LibraryEntryType], null: false
  end
end

module Types
  class LibraryEntryType < EntryType
    field :requires, [LibraryEntryType], null: false
    field :classes, [ClassEntryType], null: false
    field :methods, [MethodEntryType], null: false, resolver_method: :resolve_methods
    field :source, String, null: false
    field :sublibraries, [LibraryEntryType], null: false
    field :is_sublibrary, Boolean, null: false
    field :category, String, null: false
    field :source_location, LocationType, null: false
    field :description, String, null: false
    field :all_classes, [ClassEntryType], null: false
    field :error_classes, [ClassEntryType], null: false
    field :all_error_classes, [ClassEntryType], null: false
    field :all_modules, [ClassEntryType], null: false
    field :all_objects, [ClassEntryType], null: false
    field :classnames, [String], null: false

    def resolve_methods
      object.methods
    end
  end
end

module Types
  class MethodDatabaseType < Types::BaseObject
    description "A method database"

    field :docs, [DocEntryType], null: false
    field :classes, [ClassEntryType], null: false
    field :encoding, String, null: false
    field :version, ID, null: false

    def version
      object.propget('version')
    end
  end
end

module Types
  class QueryType < GraphQL::Schema::Object
    description "The query root of rurema schema"

    field :method_database, MethodDatabaseType, null: true do
      description "Find a method database by ID"
      argument :version, ID, required: true
    end

    def method_database(version:)
      BitClust::MethodDatabase.new("/tmp/db-#{version}")
    end
  end
end

class Schema < GraphQL::Schema
  query Types::QueryType
end

query_string = <<~GraphQL
{
  methodDatabase(version: "2.7.0") {
    encoding,
    version,
    docs {
      typeId,
      encoding,
      id,
      name,
      label,
      labels,
      title,
      sourceLocation {
        file,
        line
      }
    }
  }
}
GraphQL

pp Schema.execute(query_string).to_h
# {
#   "data" => {
#     "post" => {
#        "id" => 1,
#        "title" => "GraphQL is nice"
#        "truncatedPreview" => "GraphQL is..."
#     }
#   }
# }