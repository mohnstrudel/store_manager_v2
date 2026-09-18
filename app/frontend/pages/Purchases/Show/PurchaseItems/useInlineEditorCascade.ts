import { useForm, usePage } from "@inertiajs/react";
import { useCallback, useRef, useState } from "react";

import routes from "@/utils/routes";

import type { PurchaseItemRecord } from "../../types";

type EditorRef = { open(): void; close(): void; getValue(): string };

export function useInlineEditorCascade(purchaseItem: PurchaseItemRecord) {
  const trackingRef = useRef<EditorRef>(null);
  const shippingRef = useRef<EditorRef>(null);
  const shippingCostRef = useRef<EditorRef>(null);
  const [focusTarget, setFocusTarget] = useState<
    "tracking" | "shipping_company" | "shipping_cost" | null
  >(null);
  const [bulkErrors, setBulkErrors] = useState({ tracking_number: "", shipping_company_id: "" });
  const bulkForm = useForm({});
  const page = usePage();

  const openTracking = useCallback(() => {
    trackingRef.current?.open();
  }, []);
  const openShipping = useCallback(() => {
    shippingRef.current?.open();
  }, []);
  const openShippingCost = useCallback(() => {
    shippingCostRef.current?.open();
  }, []);

  const isBlankRow =
    !purchaseItem.tracking_number &&
    !purchaseItem.shipping_company_id &&
    parseFloat(purchaseItem.shipping_cost) === 0;

  const trackingAutoOpen = useCallback(() => {
    setFocusTarget("tracking");
    if (purchaseItem.shipping_company_id) return;
    openShipping();
    if (isBlankRow) openShippingCost();
  }, [isBlankRow, openShipping, openShippingCost, purchaseItem.shipping_company_id]);

  const shippingAutoOpen = useCallback(() => {
    if (!isBlankRow) {
      setFocusTarget("shipping_company");
      return;
    }
    setFocusTarget("tracking");
    openTracking();
    openShippingCost();
  }, [isBlankRow, openShippingCost, openTracking]);

  const costAutoOpen = useCallback(() => {
    if (!isBlankRow) {
      setFocusTarget("shipping_cost");
      return;
    }
    setFocusTarget("tracking");
    openTracking();
    openShipping();
  }, [isBlankRow, openShipping, openTracking]);

  const bulkSave = useCallback(() => {
    const tracking = trackingRef.current?.getValue() ?? "";
    const company = shippingRef.current?.getValue() ?? "";
    const rawCost = shippingCostRef.current?.getValue() ?? "";
    const cost = rawCost.trim() === "" ? "0" : rawCost;

    setBulkErrors({ tracking_number: "", shipping_company_id: "" });

    bulkForm.transform(() => ({
      purchase_item: {
        tracking_number: tracking,
        shipping_company_id: company || null,
        shipping_cost: cost,
      },
      return_to: page.url,
    }));

    bulkForm.patch(
      routes.purchaseItemsShippingDetails.update.path({ purchase_item_id: purchaseItem.id }),
      {
        only: ["purchase_items"],
        preserveScroll: true,
        onSuccess: () => {
          trackingRef.current?.close();
          shippingRef.current?.close();
          shippingCostRef.current?.close();
        },
        onError: (errors) => {
          const errs = errors as Record<string, string>;
          setBulkErrors({
            tracking_number: errs.tracking_number || "",
            shipping_company_id: errs.shipping_company_id
              ? "Shipping company is required"
              : errs.base || "",
          });
        },
      },
    );
  }, [bulkForm, purchaseItem.id, page.url]);

  return {
    bulkErrors: isBlankRow ? bulkErrors : { tracking_number: "", shipping_company_id: "" },
    bulkSave: isBlankRow ? bulkSave : undefined,
    costAutoOpen,
    focusTarget,
    shippingAutoOpen,
    shippingCostRef,
    shippingRef,
    trackingAutoOpen,
    trackingRef,
  };
}
