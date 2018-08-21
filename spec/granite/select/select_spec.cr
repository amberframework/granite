require "../../spec_helper"

describe "custom select" do
  it "generates custom SQL with the query macro" do
    ArticleViewModel.select.should eq "SELECT articles.id, articles.articlebody, comments.commentbody FROM articles JOIN comments ON comments.articleid = articles.id"
  end

  it "uses custom SQL to populate a view model - #all" do
    first = Article.new.tap do |model|
      model.articlebody = "The Article Body"
      model.save
    end

    Comment.new.tap do |model|
      model.commentbody = "The Comment Body"
      model.articleid = first.id
      model.save
    end

    viewmodel = ArticleViewModel.all
    viewmodel.first.articlebody.should eq "The Article Body"
    viewmodel.first.commentbody.should eq "The Comment Body"
  end

  # TODO:  `find` on this ViewModel fails because "id" is ambiguous in a complex SELECT.

  # it "uses custom SQL to populate a view model - #find" do
  #   first = Article.new.tap do |model|
  #     model.articlebody = "The Article Body"
  #     model.save
  #   end

  #   second = Comment.new.tap do |model|
  #     model.commentbody = "The Comment Body"
  #     model.articleid = first.id
  #     model.save
  #   end

  #   viewmodel = ArticleViewModel.find!(first.id)
  #   viewmodel.articlebody.should eq "The Article Body"
  #   viewmodel.commentbody.should eq "The Comment Body"
  # end
end
