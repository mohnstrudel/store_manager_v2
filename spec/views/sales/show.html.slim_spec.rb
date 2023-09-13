require 'rails_helper'

RSpec.describe "sales/show", type: :view do
  before(:each) do
    assign(:sale, Sale.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
