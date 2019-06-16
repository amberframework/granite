module Granite::Converters
  module UuidConverter
    def to_db(value : ::UUID) : Granite::Fields::Type
      value.to_s
    end

    def from_rs(result : ::DB::ResultSet) : ::UUID
      result.read(String?).try { |str| ::UUID.new str }
    end
  end
end
