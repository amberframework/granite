module Granite::EagerLoading
  def includes(value : Symbol)
    Granite::Querying(self).new(self.select_container, self.adapter, self.primary_name, self.quoted_table_name, self.name)
  end
end
