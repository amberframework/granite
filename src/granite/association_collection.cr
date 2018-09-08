class Granite::AssociationCollection(Owner, Target)
  forward_missing_to all

  def initialize(@owner : Owner, @foreign_key : (Symbol | String), @through : (Symbol | String | Nil) = nil)
  end

  def all(clause = "", params = [] of DB::Any)
    Target.all(
      [query, clause].join(" "),
      [owner.id] + params
    )
  end

  def find_by(**args)
    Target.first(
      "#{query} AND #{args.map { |arg| "#{Target.quote(Target.table_name)}.#{Target.quote(arg.to_s)} = ?" }.join(" AND ")}",
      [owner.id] + args.values.to_a
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
      "WHERE #{Target.table_name}.#{@foreign_key.to_s} = ?"
    else
      "JOIN #{through.to_s} ON #{through.to_s}.#{Target.to_s.underscore}_id = #{Target.table_name}.id " \
      "WHERE #{through.to_s}.#{Owner.to_s.underscore}_id = ?"
    end
  end
end
