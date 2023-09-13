require 'rails_helper'

RSpec.describe "sales/edit", type: :view do
  let(:sale) {
    Sale.create!()
  }

  before(:each) do
    assign(:sale, sale)
  end

  it "renders the edit sale form" do
    render

    assert_select "form[action=?][method=?]", sale_path(sale), "post" do
    end
  end
end
