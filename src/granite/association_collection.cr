class Granite::AssociationCollection(Owner, Target)
  forward_missing_to all

  def initialize(@owner : Owner, @through : Symbol? = nil)
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
  private getter through

  private def foreign_key
    "#{Target.table_name}.#{Owner.to_s.underscore}_id"
  end

  private def query
    if through.nil?
      "WHERE #{foreign_key} = ?"
    else
      "JOIN #{through} ON #{through}.#{Target.to_s.underscore}_id = #{Target.table_name}.id " \
      "WHERE #{through}.#{Owner.to_s.underscore}_id = ?"
    end
  end
end
