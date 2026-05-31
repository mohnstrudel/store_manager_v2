import { useCallback, useMemo, useState } from "react";
import DynamicNestedForm from "@/components/DynamicNestedForm";
import FormControl from "@/components/FormControl";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import FormSectionHeading from "@/components/FormSectionHeading";
import FormSmartSelect from "@/components/FormSmartSelect";
import ImageUploader from "@/components/ImageUploader";
import ResourceForm from "@/components/ResourceForm";
import { toSelectedOption } from "@/lib/selectOptions";
import { type SectionRow, useDynamicSection } from "@/lib/useDynamicSection";
import TiptapEditor from "./TiptapEditor";
import VariantFields from "./VariantFields";
import StoreInfoFields from "./StoreInfoFields";
import PurchaseFields from "./PurchaseFields";
import {
  type FormOptions,
  type MediaFormData,
  type ProductFormRecord,
  type PurchaseFormData,
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
const EMPTY_PAGE_ERRORS: PageErrors = {};

type ProductFormSections = ReturnType<typeof useProductFormSections>;
type StoreInfoRow = SectionRow<StoreInfoFormData>;

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
  const form = useProductFormSections(product, purchase, options);

  return (
    <ResourceForm
      action={isNew ? "/products" : product.path}
      cancelHref={isNew ? "/products" : product.path}
      method={isNew ? "post" : "patch"}
      submitLabel={submitLabel}
    >
      {({ errors }) => {
        const pageErrors = (errors ?? EMPTY_PAGE_ERRORS) as PageErrors;

        return (
          <>
            <ProductIdentityFields
              errors={pageErrors}
              options={options}
              product={product}
              selectedBrands={form.selectedBrands}
              selectedFranchise={form.selectedFranchise}
            />
            <ProductDescriptionField errors={pageErrors} product={product} />
            <ProductVariantsSection errors={pageErrors} form={form} options={options} />
            <ProductStoreInfoSection errors={pageErrors} form={form} options={options} />
            <ImageUploader media={form.media} onMediaChange={form.setMedia} />
            {isNew && <InitialPurchaseSection errors={pageErrors} form={form} options={options} />}
          </>
        );
      }}
    </ResourceForm>
  );
}

function ProductIdentityFields({
  errors,
  options,
  product,
  selectedBrands,
  selectedFranchise,
}: {
  errors: PageErrors;
  options: FormOptions;
  product: ProductFormRecord;
  selectedBrands: FormOptions["brands"];
  selectedFranchise: FormOptions["franchises"][number] | null;
}) {
  return (
    <FormRow>
      <FormSmartSelect
        className="lg:w-2/3"
        defaultValue={selectedFranchise}
        error={errors.franchise ?? errors.franchise_id}
        inputId="product_franchise_id"
        isClearable
        label="Franchise"
        name="product[franchise_id]"
        options={options.franchises}
      />

      <FormInput
        defaultValue={product.title}
        error={errors.title}
        label="Title"
        name="product[title]"
      />

      <FormControl className="lg:w-1/4" error={errors.shape} htmlFor="product_shape" label="Shape">
        <select id="product_shape" name="product[shape]" defaultValue={product.shape}>
          {options.shapes.map((shape) => (
            <option key={shape} value={shape}>
              {shape}
            </option>
          ))}
        </select>
      </FormControl>

      <FormSmartSelect
        className="lg:w-2/3"
        defaultValue={selectedBrands}
        error={errors.brand_ids}
        inputId="product_brand_ids"
        isMulti
        label="Brand"
        name="product[brand_ids][]"
        options={options.brands}
      />
    </FormRow>
  );
}

function ProductDescriptionField({
  errors,
  product,
}: {
  errors: PageErrors;
  product: ProductFormRecord;
}) {
  return (
    <div>
      <label htmlFor="product[description]">Description</label>
      <TiptapEditor defaultValue={product.description_html} name="product[description]" />
      {errors.description && <p className="text_error mt-2">{errors.description}</p>}
    </div>
  );
}

function ProductVariantsSection({
  errors,
  form,
  options,
}: {
  errors: PageErrors;
  form: ProductFormSections;
  options: FormOptions;
}) {
  return (
    <DynamicNestedForm name="Variant" onAdd={form.variants.add} title="Variants">
      {form.variants.items.map((variant, index) => (
        <VariantFields
          colors={options.colors}
          errors={errors}
          index={index}
          key={variant.clientKey}
          onRemove={form.variants.removeAt}
          sizes={options.sizes}
          variant={variant}
          versions={options.versions}
        />
      ))}
    </DynamicNestedForm>
  );
}

function ProductStoreInfoSection({
  errors,
  form,
  options,
}: {
  errors: PageErrors;
  form: ProductFormSections;
  options: FormOptions;
}) {
  return (
    <DynamicNestedForm
      canAdd={canAddStoreInfo(form.storeInfos.items, options.store_names)}
      name="Store Info"
      onAdd={form.storeInfos.add}
      title="Store Information"
    >
      {form.storeInfos.items.map((storeInfo, index) => (
        <StoreInfoFields
          errors={errors}
          index={index}
          key={storeInfo.clientKey}
          onRemove={form.storeInfos.removeAt}
          storeInfo={storeInfo}
          storeNames={options.store_names}
        />
      ))}
    </DynamicNestedForm>
  );
}

function InitialPurchaseSection({
  errors,
  form,
  options,
}: {
  errors: PageErrors;
  form: ProductFormSections;
  options: FormOptions;
}) {
  const renderPurchase = form.showPurchase || shouldShowPurchase(form.initialPurchase, errors);

  return (
    <section>
      <FormSectionHeading
        subtitle="Add a purchase if you want to create one alongside the product."
        title="Purchase"
      />

      {!renderPurchase && (
        <button className="btn_rounded" onClick={form.showPurchaseForm} type="button">
          Add Purchase
        </button>
      )}

      {renderPurchase && (
        <PurchaseFields
          errors={errors}
          purchase={form.initialPurchase}
          suppliers={options.suppliers}
          warehouses={options.warehouses}
        />
      )}
    </section>
  );
}

function useProductFormSections(
  product: ProductFormRecord,
  purchase: PurchaseFormData | undefined,
  options: FormOptions,
) {
  const initialPurchase = purchase ?? defaultPurchase();
  const variants = useDynamicSection(product.variants, newVariant, {
    keyForInitial: (variant, index) =>
      variant.id ? `variant-${variant.id}` : `initial-variant-${index}`,
  });
  const storeInfos = useDynamicSection(product.store_infos, newStoreInfo, {
    keyForInitial: (storeInfo, index) =>
      storeInfo.id ? `store-info-${storeInfo.id}` : `initial-store-info-${index}`,
  });
  const [showPurchase, setShowPurchase] = useState(() => shouldShowPurchase(initialPurchase, {}));
  const [media, setMedia] = useState<MediaFormData[]>(() => product.media);

  const selectedFranchise = useMemo(
    () => toSelectedOption(options.franchises, product.franchise_id),
    [options.franchises, product.franchise_id],
  );

  const selectedBrands = useMemo(
    () => options.brands.filter((brand) => product.brand_ids.includes(brand.value)),
    [options.brands, product.brand_ids],
  );

  const showPurchaseForm = useCallback(() => setShowPurchase(true), []);

  return {
    initialPurchase,
    media,
    selectedBrands,
    selectedFranchise,
    setMedia,
    showPurchase,
    showPurchaseForm,
    storeInfos,
    variants,
  };
}

function canAddStoreInfo(storeInfos: StoreInfoRow[], storeNames: string[]) {
  return storeInfos.filter((storeInfo) => !storeInfo._destroy).length < storeNames.length;
}
