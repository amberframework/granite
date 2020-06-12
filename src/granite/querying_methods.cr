module Granite::QueringMethods
  def __quering
    Granite::Querying(self).new(self.select_container)
  end

  delegate from_rs, raw_all, all, first, first!, find,
	   find!, find_by, find_by!, find_each, find_in_batches,
           exists?, count, exec, query, scalar,  to: __quering
end
