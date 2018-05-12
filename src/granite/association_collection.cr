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

  def find_by(field : String | Symbol, value)
    Target.first(
      [query, "AND #{Target.table_name}.#{field} = ?"].join(" "),
      [owner.id, value]
    )
  end

  def find_by!(field : String | Symbol, value)
    find_by(field, value) ||
      raise Granite::Querying::NotFound.new(
        "Couldn't find #{Target.name} with #{field}=#{value}"
      )
  end

  def find(value)
    find_by(Target.primary_name, value)
  end

  def find!(value)
    find_by!(Target.primary_name, value)
  end

  private getter owner
  private getter through

  private def foreign_key
    "#{Target.table_name}.#{Owner.table_name[0...-1]}_id"
  end

  private def query
    if through.nil?
      "WHERE #{foreign_key} = ?"
    else
      "JOIN #{through} ON #{through}.#{Target.table_name[0...-1]}_id = #{Target.table_name}.id " \
      "WHERE #{through}.#{Owner.table_name[0...-1]}_id = ?"
    end
  end
end
