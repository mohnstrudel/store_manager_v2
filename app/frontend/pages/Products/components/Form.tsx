import { useRef, useState } from "react";
import FieldSet from "@/components/FieldSet";
import FormInput from "@/components/FormInput";
import FormSectionHeading from "@/components/FormSectionHeading";
import FormSmartSelect from "@/components/FormSmartSelect";
import ResourceForm from "@/components/ResourceForm";
import TiptapEditor from "./TiptapEditor";
import VariantFields from "./VariantFields";
import StoreInfoFields from "./StoreInfoFields";
import PurchaseFields from "./PurchaseFields";
import ImageUploader from "./ImageUploader";
import {
  type FormOptions,
  type MediaFormData,
  type ProductFormRecord,
  type PurchaseFormData,
  type SelectOption,
  type StoreInfoFormData,
  type VariantFormData,
} from "../types";

type ProductFormProps = {
  isNew: boolean;
  options: FormOptions;
  product: ProductFormRecord;
  purchase?: PurchaseFormData;
  submitLabel: string;
};

type PageErrors = Record<string, string | undefined>;
type VariantRow = VariantFormData & { clientKey: string };
type StoreInfoRow = StoreInfoFormData & { clientKey: string };

function toSelectedOption(
  options: SelectOption<number>[],
  value: number | null,
): SelectOption<number> | null {
  return options.find((option) => option.value === value) ?? null;
}

function defaultPurchase(): PurchaseFormData {
  return {
    supplier_id: null,
    order_reference: "",
    item_price: "",
    amount: "",
    warehouse_id: null,
    payment_value: "",
  };
}

function newVariant(): VariantFormData {
  return {
    id: null,
    sku: "",
    size_id: null,
    version_id: null,
    color_id: null,
    purchase_cost: "0",
    selling_price: "0",
    weight: "0",
    deactivated: false,
    has_sales_or_purchases: false,
    _destroy: false,
  };
}

function newStoreInfo(): StoreInfoFormData {
  return {
    id: null,
    store_name: "",
    tag_list: "",
    _destroy: false,
  };
}

function shouldShowPurchase(purchase: PurchaseFormData, errors: PageErrors) {
  const hasPurchaseValues = [
    purchase.supplier_id,
    purchase.order_reference,
    purchase.item_price,
    purchase.amount,
    purchase.payment_value,
  ].some((value) => value !== null && value !== "");

  const hasPurchaseErrors = Object.keys(errors).some((key) => key.startsWith("purchase."));

  return hasPurchaseValues || hasPurchaseErrors || !!errors.initial_purchase;
}

export default function ProductForm({
  isNew,
  options,
  product,
  purchase,
  submitLabel,
}: ProductFormProps) {
  const initialPurchase = purchase ?? defaultPurchase();
  const rowSequence = useRef(0);
  const [variants, setVariants] = useState<VariantRow[]>(() =>
    product.variants.map((variant, index) => ({
      ...variant,
      clientKey: variant.id ? `variant-${variant.id}` : `initial-variant-${index}`,
    })),
  );
  const [storeInfos, setStoreInfos] = useState<StoreInfoRow[]>(() =>
    product.store_infos.map((storeInfo, index) => ({
      ...storeInfo,
      clientKey: storeInfo.id ? `store-info-${storeInfo.id}` : `initial-store-info-${index}`,
    })),
  );
  const [showPurchase, setShowPurchase] = useState(() => shouldShowPurchase(initialPurchase, {}));
  const [media, setMedia] = useState<MediaFormData[]>(() => product.media);

  const action = isNew ? "/products" : product.path;
  const method = isNew ? "post" : "patch";
  const franchiseOpt = toSelectedOption(options.franchises, product.franchise_id);
  const selectedBrands = options.brands.filter((brand) => product.brand_ids.includes(brand.value));

  function removeVariant(index: number) {
    setVariants((current) => current.filter((_, variantIndex) => variantIndex !== index));
  }

  function addVariant() {
    const clientKey = `new-variant-${rowSequence.current++}`;
    setVariants((current) => [...current, { ...newVariant(), clientKey }]);
  }

  function removeStoreInfo(index: number) {
    setStoreInfos((current) => current.filter((_, storeInfoIndex) => storeInfoIndex !== index));
  }

  function addStoreInfo() {
    const clientKey = `new-store-info-${rowSequence.current++}`;
    setStoreInfos((current) => [...current, { ...newStoreInfo(), clientKey }]);
  }

  return (
    <ResourceForm
      action={action}
      cancelHref={isNew ? "/products" : product.path}
      method={method}
      submitLabel={submitLabel}
    >
      {({ errors }) => {
        const pageErrors = (errors ?? {}) as PageErrors;
        const franchiseError = pageErrors.franchise_id;
        const titleError = pageErrors.title;
        const shapeError = pageErrors.shape;
        const brandError = pageErrors.brand_ids;
        const descriptionError = pageErrors.description;
        const renderPurchase = showPurchase || shouldShowPurchase(initialPurchase, pageErrors);

        return (
          <>
            <FieldSet>
              <FormSmartSelect
                className="lg:w-2/3"
                defaultValue={franchiseOpt}
                error={franchiseError}
                inputId="product_franchise_id"
                isClearable
                label="Franchise"
                name="product[franchise_id]"
                options={options.franchises}
              />
              <FormInput
                defaultValue={product.title}
                error={titleError}
                label="Title"
                name="product[title]"
              />
              <div className="lg:w-1/4">
                <label htmlFor="product_shape">Shape</label>
                <select id="product_shape" name="product[shape]" defaultValue={product.shape}>
                  {options.shapes.map((shape) => (
                    <option key={shape} value={shape}>
                      {shape}
                    </option>
                  ))}
                </select>
                {shapeError && <p className="text-error mt-2">{shapeError}</p>}
              </div>
              <FormSmartSelect
                className="lg:w-2/3"
                defaultValue={selectedBrands}
                error={brandError}
                inputId="product_brand_ids"
                isMulti
                label="Brand"
                name="product[brand_ids][]"
                options={options.brands}
              />
            </FieldSet>

            <div className="mt-6">
              <label htmlFor="product[description]">Description</label>
              <TiptapEditor defaultValue={product.description_html} name="product[description]" />
              {descriptionError && <p className="text-error mt-2">{descriptionError}</p>}
            </div>

            <section className="mt-6">
              <FormSectionHeading subtitle="Manage variants for this product" title="Variants" />

              <div className="grid grid-cols-1 gap-x-6 gap-y-4 lg:grid-cols-2">
                {variants.map((variant, index) => (
                  <VariantFields
                    colors={options.colors}
                    errors={pageErrors}
                    index={index}
                    key={variant.clientKey}
                    onRemove={removeVariant}
                    sizes={options.sizes}
                    variant={variant}
                    versions={options.versions}
                  />
                ))}
              </div>

              <button className="btn-rounded mt-4" onClick={addVariant} type="button">
                Add Variant
              </button>
            </section>

            <section className="mt-6">
              <FormSectionHeading subtitle="Manage store information for this product" title="Store Information" />

              <div className="flex flex-col gap-4">
                {storeInfos.map((storeInfo, index) => (
                  <StoreInfoFields
                    errors={pageErrors}
                    index={index}
                    key={storeInfo.clientKey}
                    onRemove={removeStoreInfo}
                    storeInfo={storeInfo}
                    storeNames={options.store_names}
                  />
                ))}
              </div>

              {storeInfos.filter((s) => !s._destroy).length < options.store_names.length && (
                <button className="btn-rounded mt-4" onClick={addStoreInfo} type="button">
                  Add Store Info
                </button>
              )}
            </section>

            <ImageUploader media={media} onMediaChange={setMedia} />

            {isNew && (
              <fieldset className="mt-6">
                <FormSectionHeading subtitle="Add a purchase if you want to create one alongside the product." title="Purchase" />

                {!renderPurchase && (
                  <button
                    className="btn-rounded"
                    onClick={() => setShowPurchase(true)}
                    type="button"
                  >
                    Add Purchase
                  </button>
                )}

                {renderPurchase && (
                  <PurchaseFields
                    errors={pageErrors}
                    purchase={initialPurchase}
                    suppliers={options.suppliers}
                    warehouses={options.warehouses}
                  />
                )}
              </fieldset>
            )}
          </>
        );
      }}
    </ResourceForm>
  );
}
