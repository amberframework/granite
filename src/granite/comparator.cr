# Adds equals, hash, and comparison methods to Granite::Base objects.
module Granite::Comparator

  macro __process_comparator

    def_equals_and_hash {{ *FIELDS.keys }}

    # Compares this {{@type}} to another {{@type}} by comparing their fields in this order: {{ FIELDS.keys.join(", ").id }}.
    # 
    # Each individual field will be compared using the <=> (if available).
    #
    # Returns 0 if the two objects are equal, a negative number if this object is considered less than other, or a positive number otherwise.
    def <=>(other : {{@type}})
      {% for field, options in FIELDS %}
        if self.{{field}} && !other.{{field}}
          return -1
        elsif !self.{{field}} && other.{{field}}
          return 1
        elsif self.{{field}} != other.{{field}}
          {% 
            type = options[:type]
            type_node = options[:type].resolve
          %}
          {% if type_node.has_method?("<=>") %}
            n = self.{{field}}.as({{type}}) <=> other.{{field}}.as({{type}})
            return n unless n == 0
          {% end %}
        end
      {% end %}
      0
    end

    include Comparable(self)

  end

end
