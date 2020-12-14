require "../../spec_helper"

describe "belongs_to" do
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

  it "supports custom types for the join" do
    book = Book.new
    book.name = "Screw driver"
    book.save

    review = BookReview.new
    review.book = book
    review.body = "Best book ever!"
    review.save

    review.book.name.should eq "Screw driver"
  end

  it "supports custom method name" do
    author = Person.new
    author.name = "John Titor"
    author.save

    book = Book.new
    book.name = "How to Time Traveling"
    book.author = author
    book.save

    book.author.name.should eq "John Titor"
  end

  it "supports both custom method name and custom types for the join" do
    publisher = Company.new
    publisher.name = "Amber Framework"
    publisher.save

    book = Book.new
    book.name = "Introduction to Granite"
    book.publisher = publisher
    book.save

    book.publisher.name.should eq "Amber Framework"
  end

  it "supports json_options" do
    publisher = Company.new
    publisher.name = "Amber Framework"
    publisher.save

    book = Book.new
    book.name = "Introduction to Granite"
    book.publisher = publisher
    book.save
    book.to_json.should eq %({"id":#{book.id},"name":"Introduction to Granite"})
  end

  it "supports yaml_options" do
    publisher = Company.new
    publisher.name = "Amber Framework"
    publisher.save

    book = Book.new
    book.name = "Introduction to Granite"
    book.publisher = publisher
    book.save
    book.to_yaml.should eq %(---\nid: #{book.id}\nname: Introduction to Granite\n)
  end

  it "provides a method to retrieve parent object that will raise if record is not found" do
    book = Book.new
    book.name = "Introduction to Granite"

    expect_raises Granite::Querying::NotFound, "No Company found where id is NULL" { book.publisher! }
  end

  it "provides the ability to use a custom primary key" do
    courier = Courier.new
    courier.courier_id = 139_132_751
    courier.issuer_id = 999

    service = CourierService.new
    service.owner_id = 123_321
    service.name = "My Service"
    service.save

    courier.service = service
    courier.save

    courier.service!.owner_id.should eq 123_321
  end

  it "allows a belongs_to association to be a primary key" do
    chat = Chat.new
    chat.name = "My Awesome Chat"
    chat.save

    settings = ChatSettings.new
    settings.chat = chat
    settings.save

    settings.chat_id!.should eq chat.id
  end
end
