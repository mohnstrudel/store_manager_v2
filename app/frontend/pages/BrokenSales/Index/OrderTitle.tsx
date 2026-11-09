import { Link } from "@inertiajs/react";

type StoreType = "shopify" | "woo";

type OrderTitleProps = {
  path: string | null;
  storeType: StoreType | null;
  title: string;
};

const storeLabels: Record<StoreType, string> = {
  shopify: "Shopify",
  woo: "Woo",
};

export default function OrderTitle({ path, storeType, title }: OrderTitleProps) {
  const content = (
    <>
      {storeType === "shopify" && (
        <span aria-hidden="true" className="inline-block icon_shopify w-5 h-5 mr-1" />
      )}
      {storeType === "woo" && (
        <span aria-hidden="true" className="inline-block icon_woo w-8 h-8 mr-2" />
      )}
      {title}
    </>
  );

  if (!path) return content;

  return (
    <Link aria-label={orderName(storeType, title)} href={path}>
      {content}
    </Link>
  );
}

export function orderName(storeType: StoreType | null, title: string) {
  return storeType ? `${storeLabels[storeType]} order ${title}` : title;
}
