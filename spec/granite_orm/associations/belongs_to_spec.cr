require "../../spec_helper"

{% for adapter in GraniteExample::ADAPTERS %}
module {{adapter.capitalize.id}}
  describe "{{ adapter.id }} belongs_to" do
    it "provides a getter for the foreign entity" do
      teacher = Teacher.new
      teacher.name = "Test teacher"
      teacher.save

      klass = Klass.new
      klass.name = "Test klass"
      klass.teacher_id = teacher.id
      klass.save

      klass.teacher.id.should eq teacher.id
    end

    it "provides a setter for the foreign entity" do
      teacher = Teacher.new
      teacher.name = "Test teacher"
      teacher.save

      klass = Klass.new
      klass.name = "Test klass"
      klass.teacher = teacher
      klass.save

      klass.teacher_id.should eq teacher.id
    end
  end
end
{% end %}
