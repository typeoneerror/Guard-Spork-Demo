require 'spec_helper'


describe Article do

  it 'should test some silly thing that will pass' do
    @article = Article.new(:title => 'The Title')
    @article.should be_valid
  end
  
  it 'should test some silly thing that will fail' do
    @article = Article.new
    @article.should be_valid
  end

end
