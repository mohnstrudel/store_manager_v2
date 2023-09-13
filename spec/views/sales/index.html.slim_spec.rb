require 'rails_helper'

RSpec.describe "sales/index", type: :view do
  before(:each) do
    assign(:sales, [
      Sale.create!(),
      Sale.create!()
    ])
  end

  it "renders a list of sales" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
  end
end
