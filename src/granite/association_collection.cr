class Granite::AssociationCollection(Owner, Target)
  forward_missing_to all

  def initialize(@owner : Owner, @foreign_key : (Symbol | String), @through : (Symbol | String | Nil) = nil)
  end

  def all(clause = "", params = [] of DB::Any)
    Target.all(
      [query, clause].join(" "),
      [owner.primary_key_value] + params
    )
  end

  def find_by(**args)
    Target.first(
      "#{query} AND #{args.map { |arg| "#{Target.quote(Target.table_name)}.#{Target.quote(arg.to_s)} = ?" }.join(" AND ")}",
      [owner.primary_key_value] + args.values.to_a
    )
  end

  def find_by!(**args)
    find_by(**args) || raise Granite::Querying::NotFound.new("No #{Target.name} found where #{args.map { |k, v| "#{k} = #{v}" }.join(" and ")}")
  end

  def find(value)
    Target.find(value)
  end

  def find!(value)
    Target.find!(value)
  end

  private getter owner
  private getter foreign_key
  private getter through

  private def query
    if through.nil?
      "WHERE #{Target.table_name}.#{@foreign_key} = ?"
    else
      "JOIN #{through} ON #{through}.#{Target.to_s.underscore}_id = #{Target.table_name}.#{Target.primary_name} " \
      "WHERE #{through}.#{@foreign_key} = ?"
    end
  end
end
