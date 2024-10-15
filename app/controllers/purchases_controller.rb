class PurchasesController < ApplicationController
  before_action :set_default_warehouse_id, only: %i[new edit]
  before_action :set_purchase, only: %i[show edit update destroy]

  # GET /purchases or /purchases.json
  def index
    @purchases = Purchase
      .includes(
        :supplier,
        :payments,
        purchased_products: [:warehouse],
        product: [images_attachments: :blob],
        variation: [:color, :size, :version]
      )
      .order(id: :desc)
      .page(params[:page])
    @purchases = @purchases.search(params[:q]) if params[:q].present?
  end

  # GET /purchases/1 or /purchases/1.json
  def show
    @purchased_products = @purchase
      .purchased_products
      .includes(:warehouse, :product_sale)
      .order(updated_at: :desc)
  end

  # GET /purchases/new
  def new
    @purchase = Purchase.new
    @purchase.payments.build
    if params[:product]
      product = Product.friendly.find(params[:product])
      @purchase.product = product
    end
  end

  # GET /purchases/1/edit
  def edit
  end

  # POST /purchases or /purchases.json
  def create
    @purchase = Purchase.new(purchase_params)

    respond_to do |format|
      if @purchase.save
        format.html { redirect_to purchase_url(@purchase), notice: "Purchase was successfully created." }
        format.json { render :show, status: :created, location: @purchase }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /purchases/1 or /purchases/1.json
  def update
    respond_to do |format|
      if @purchase.update(purchase_params.merge(slug: nil))
        format.html { redirect_to purchase_url(@purchase), notice: "Purchase was successfully updated." }
        format.json { render :show, status: :ok, location: @purchase }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /purchases/1 or /purchases/1.json
  def destroy
    @purchase.destroy

    respond_to do |format|
      format.html { redirect_to purchases_url, notice: "Purchase was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def move
    purchase_id = params[:purchase_id]
    purchases_ids = params[:selected_items_ids]
    purchases_ids = purchase_id if purchases_ids.blank?

    destination_id = params[:destination_id]
    destination_warehouse = Warehouse.find(destination_id)

    moved_count = 0

    Purchase.where(id: purchases_ids).find_each do |purchase|
      if purchase.purchased_products.empty?
        purchase.amount.times do
          purchase.purchased_products.create(warehouse_id: destination_id)
          moved_count += 1
        end
      else
        moved_count += purchase.purchased_products.update_all(warehouse_id: destination_id)
      end
    end

    if moved_count > 0
      flash[:notice] = "Success! #{moved_count} purchased #{"product".pluralize(moved_count)} moved to: #{view_context.link_to(destination_warehouse.name, warehouse_path(destination_warehouse))}".html_safe
    end

    if purchase_id.present?
      redirect_to purchase_path(Purchase.find(purchase_id))
    else
      redirect_to purchases_path
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_purchase
    @purchase = Purchase.friendly.find(params[:id])
  end

  def set_default_warehouse_id
    @default_warehouse_id = Warehouse.find_by(is_default: true)&.id
  end

  # Only allow a list of trusted parameters through.
  def purchase_params
    params.require(:purchase).permit(
      :supplier_id,
      :product_id,
      :variation_id,
      :order_reference,
      :item_price,
      :amount,
      :purchase_id,
      :selected_items_ids,
      payments_attributes: [:id, :value, :purchase_id]
    )
  end
end
