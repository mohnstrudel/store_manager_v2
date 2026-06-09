import { getFormString } from "@/utils/formSchema";
import { msg } from "@/utils/validationMessages";
import { validateProductForm } from "./productFormSchema";
import type { PurchaseFormData, VariantFormData } from "../types";

type ValidateProductFormSubmissionInput = {
  formData: FormData;
  initialPurchase: PurchaseFormData;
  showPurchase: boolean;
  variants: VariantFormData[];
};

export function validateProductFormSubmission({
  formData,
  initialPurchase,
  showPurchase,
  variants,
}: ValidateProductFormSubmissionInput): Record<string, string> | null {
  const liveVariants = variants.map((variant, index) =>
    mergeVariantFromFormData(formData, variant, index),
  );
  const livePurchase = mergePurchaseFromFormData(formData, initialPurchase);

  const errors = validateProductForm({
    title: getFormString(formData, "product[title]"),
    variants: liveVariants,
    showPurchase,
    initialPurchase: livePurchase,
  });

  return addSummaryErrors(errors);
}

function mergeVariantFromFormData(
  formData: FormData,
  variant: VariantFormData,
  index: number,
): VariantFormData {
  return {
    ...variant,
    sku: getFormString(formData, `variants[${index}][sku]`),
    size_id: getNullableNumberFromFormData(formData, `variants[${index}][size_id]`),
    version_id: getNullableNumberFromFormData(formData, `variants[${index}][version_id]`),
    color_id: getNullableNumberFromFormData(formData, `variants[${index}][color_id]`),
    purchase_cost: getFormString(formData, `variants[${index}][purchase_cost]`),
    selling_price: getFormString(formData, `variants[${index}][selling_price]`),
    weight: getFormString(formData, `variants[${index}][weight]`),
    _destroy: getBooleanFromFormData(formData, `variants[${index}][_destroy]`),
  };
}

function mergePurchaseFromFormData(
  formData: FormData,
  purchase: PurchaseFormData,
): PurchaseFormData {
  return {
    ...purchase,
    supplier_id: getNullableNumberFromFormData(formData, "purchase[supplier_id]"),
    order_reference: getFormString(formData, "purchase[order_reference]"),
    item_price: getFormString(formData, "purchase[item_price]"),
    amount: getFormString(formData, "purchase[amount]"),
    warehouse_id: getNullableNumberFromFormData(formData, "purchase[warehouse_id]"),
    payment_value: getFormString(formData, "purchase[payment_value]"),
  };
}

function addSummaryErrors(errors: Record<string, string> | null): Record<string, string> | null {
  if (!errors) return null;

  const nextErrors = { ...errors };
  const errorKeys = Object.keys(errors);

  if (errorKeys.some((key) => key.startsWith("variants."))) {
    nextErrors.variants ??= msg.invalid;
  }

  if (errorKeys.some((key) => key.startsWith("purchase."))) {
    nextErrors.initial_purchase ??= msg.invalid;
  }

  return nextErrors;
}

function getBooleanFromFormData(formData: FormData, key: string): boolean {
  return formData.getAll(key).some((value) => value === "1" || value === "true" || value === "on");
}

function getNullableNumberFromFormData(formData: FormData, key: string): number | null {
  const value = getFormString(formData, key);
  if (value.trim() === "") return null;

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}
