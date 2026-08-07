import { lazy, Suspense, useCallback, useEffect, useMemo, useState } from "react";
import DynamicNestedForm from "@/components/DynamicNestedForm";
import FormControl from "@/components/FormControl";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import FormSectionHeading from "@/components/FormSectionHeading";
import FormSmartSelect from "@/components/FormSmartSelect";
import ImageUploader from "@/components/ImageUploader";
import ResourceForm from "@/components/ResourceForm";
import { toSelectedOption } from "@/utils/selectOptions";
import { type SectionRow, useDynamicSection } from "@/utils/useDynamicSection";

const TiptapEditor = lazy(() => import("./Form/TiptapEditor"));
const TIPTAP_FALLBACK = <TiptapSkeleton />;
import VariantFields from "./Form/VariantFields";
import StoreInfoFields from "./Form/StoreInfoFields";
import PurchaseFields from "./Form/PurchaseFields";
import {
  type FormOptions,
  type MediaFormData,
  type ProductFormRecord,
  type PurchaseFormData,
  type StoreInfoFormData,
  type VariantFormData,
} from "../types";
import { validateProductFormSubmission } from "./productFormValidation";
import { draftVariantAvailability, visibleDraftVariants } from "./variantDrafts";

type ProductFormProps = {
  isNew: boolean;
  options: FormOptions;
  product: ProductFormRecord;
  purchase?: PurchaseFormData;
  submitLabel: string;
};

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
    variant_client_key: null,
  };
}

function newVariant(): VariantFormData {
  return {
    id: null,
    base_model: false,
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

function shouldShowPurchase(purchase: PurchaseFormData, errors: Record<string, string>) {
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

  const validate = useCallback(
    (formData: FormData) =>
      validateProductFormSubmission({
        formData,
        initialPurchase: form.initialPurchase,
        showPurchase: form.showPurchase,
        variants: form.variants.items,
      }),
    [form.variants.items, form.showPurchase, form.initialPurchase],
  );

  return (
    <ResourceForm
      action={isNew ? "/products" : product.path}
      cancelHref={isNew ? "/products" : product.path}
      method={isNew ? "post" : "patch"}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <>
          <ProductIdentityFields
            errors={errors}
            options={options}
            product={product}
            selectedBrands={form.selectedBrands}
            selectedFranchise={form.selectedFranchise}
          />
          <ProductDescriptionField errors={errors} product={product} />
          <ProductVariantsSection errors={errors} form={form} isNew={isNew} options={options} />
          <ProductStoreInfoSection errors={errors} form={form} options={options} />
          <ImageUploader media={form.media} onMediaChange={form.setMedia} />
          {isNew && <InitialPurchaseSection errors={errors} form={form} options={options} />}
        </>
      )}
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
  errors: Record<string, string>;
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
        error={errors.franchise || errors.franchise_id}
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
  errors: Record<string, string>;
  product: ProductFormRecord;
}) {
  return (
    <div>
      <label htmlFor="product[description]">Description</label>
      <Suspense fallback={TIPTAP_FALLBACK}>
        <TiptapEditor defaultValue={product.description_html} name="product[description]" />
      </Suspense>
      {errors.description && <p className="text_error mt-2">{errors.description}</p>}
    </div>
  );
}

function TiptapSkeleton() {
  return (
    <div className="border border-gray-300 dark:border-gray-600 rounded overflow-hidden">
      <div className="h-10 bg-gray-50 dark:bg-gray-800 border-b border-gray-300 dark:border-gray-600 animate-pulse" />
      <div className="min-h-48 animate-pulse bg-white dark:bg-gray-900" />
    </div>
  );
}

function ProductVariantsSection({
  errors,
  form,
  isNew,
  options,
}: {
  errors: Record<string, string>;
  form: ProductFormSections;
  isNew: boolean;
  options: FormOptions;
}) {
  const variants = isNew ? visibleDraftVariants(form.variants.items) : form.variants.items;

  return (
    <DynamicNestedForm name="Variant" onAdd={form.variants.add} title="Variants">
      {variants.map((variant, index) => (
        <VariantFields
          colors={options.colors}
          errors={errors}
          index={index}
          key={variant.clientKey}
          onChange={form.variants.update}
          onRemove={form.variants.remove}
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
  errors: Record<string, string>;
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
  errors: Record<string, string>;
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
          draftAvailability={form.draftVariantAvailability}
          errors={errors}
          onVariantChange={form.selectDraftVariant}
          purchase={form.initialPurchase}
          suppliers={options.suppliers}
          variantClientKey={form.variantClientKey}
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
  const availability = useMemo(
    () => draftVariantAvailability(variants.items, options),
    [options, variants.items],
  );
  const [variantClientKey, setVariantClientKey] = useState<string | null>(
    initialPurchase.variant_client_key,
  );
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
  const selectDraftVariant = useCallback(
    (clientKey: string | null) => setVariantClientKey(clientKey),
    [],
  );

  useEffect(() => {
    const candidateKeys = availability.variants.map((variant) => variant.value);

    if (availability.mode === "base") {
      setVariantClientKey(candidateKeys[0] ?? null);
      return;
    }

    if (variantClientKey && !candidateKeys.includes(variantClientKey)) {
      setVariantClientKey(null);
    }
  }, [availability, variantClientKey]);

  return {
    draftVariantAvailability: availability,
    initialPurchase,
    media,
    selectDraftVariant,
    selectedBrands,
    selectedFranchise,
    setMedia,
    showPurchase,
    showPurchaseForm,
    storeInfos,
    variants,
    variantClientKey,
  };
}

function canAddStoreInfo(storeInfos: StoreInfoRow[], storeNames: string[]) {
  return storeInfos.filter((storeInfo) => !storeInfo._destroy).length < storeNames.length;
}
