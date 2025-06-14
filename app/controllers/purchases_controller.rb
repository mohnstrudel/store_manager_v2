class PurchasesController < ApplicationController
  include WarehouseMovementNotification

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
        edition: [:color, :size, :version]
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
    warehouse_id = purchase_params.delete(:warehouse_id)
    @purchase = Purchase.new(purchase_params.except(:warehouse_id))

    respond_to do |format|
      if @purchase.save
        warehouse = Warehouse.find_by(id: warehouse_id) ||
          Warehouse.find_by(is_default: true)

        if warehouse.present?
          Array.new(@purchase.amount) do
            warehouse.purchased_products.create(purchase_id: @purchase.id)
          end

          purchased_product_ids = PurchaseLinker.new(@purchase).link

          PurchasedNotifier.new(purchased_product_ids:).handle_product_purchase
        end

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
    purchases_ids = params[:selected_items_ids].presence || purchase_id
    destination_id = params[:destination_id]

    moved_count = Purchase.friendly
      .where(id: purchases_ids)
      .sum { |purchase|
        ProductMover.new(warehouse_id: destination_id, purchase:).move
      }

    flash_movement_notice(moved_count, Warehouse.find(destination_id))

    if purchase_id
      redirect_to purchase_path(Purchase.friendly.find(purchase_id))
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
      :edition_id,
      :order_reference,
      :item_price,
      :amount,
      :purchase_id,
      :selected_items_ids,
      :warehouse_id,
      payments_attributes: [:id, :value, :purchase_id]
    )
  end
end
