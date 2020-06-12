module Granite::EagerLoading
  def includes(value : Symbol)
    Granite::Querying(self).new(self.select_container)
  end
end
