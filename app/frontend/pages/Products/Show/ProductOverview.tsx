import CopyToClipboardButton from "@/components/CopyToClipboardButton";
import Field from "@/components/Field";
import ImageGallery from "@/components/ImageGallery";

import { type ProductShowRecord, type TimestampColumn } from "../types";

type ProductOverviewProps = {
  product: ProductShowRecord;
};

export default function ProductOverview({ product }: ProductOverviewProps) {
  return (
    <div className="cards">
      <ImageGallery media={product.media} />
      <ProductDetailsCard product={product} />
      <StoreIdentifiersCard product={product} />
    </div>
  );
}

function ProductDetailsCard({ product }: ProductOverviewProps) {
  return (
    <dl className="card grow">
      <Field label="Title" value={product.title} />
      <Field label="Franchise" value={product.franchise.title} />
      <Field label="Version" value={formatList(product.versions.map((version) => version.value))} />
      <Field label="Brand" value={formatList(product.brands.map((brand) => brand.title))} />
      <Field label="Size" value={formatList(product.sizes.map((size) => size.value))} />
      <Field label="Shape" value={product.shape} />
      <Field label="Color" value={formatList(product.colors.map((color) => color.value))} />
    </dl>
  );
}

function StoreIdentifiersCard({ product }: ProductOverviewProps) {
  return (
    <dl className="card w-min">
      <Field label="ID" value={product.id} />
      <dt>Created&nbsp;At</dt>
      <dd>
        <TimestampColumns columns={product.created_at_columns} />
      </dd>
      <dt>Updated&nbsp;At</dt>
      <dd>
        <TimestampColumns columns={product.updated_at_columns} />
      </dd>
      <WooIdentifier product={product} />
      <ShopifyIdentifier product={product} />
      <ShopifyTags product={product} />
    </dl>
  );
}

function WooIdentifier({ product }: ProductOverviewProps) {
  const wooInfo = product.woo_info;

  return (
    <Field label="Woo ID" value={wooInfo?.store_id}>
      {wooInfo?.product_url ? (
        <a className="link" href={wooInfo.product_url} rel="noopener noreferrer" target="_blank">
          {wooInfo.store_id}
        </a>
      ) : (
        wooInfo?.store_id
      )}
      {wooInfo?.store_id && (
        <CopyToClipboardButton className="text-xs btn_xs" text={wooInfo.store_id} />
      )}
    </Field>
  );
}

function ShopifyIdentifier({ product }: ProductOverviewProps) {
  const shopifyInfo = product.shopify_info;

  return (
    <Field className="flex gap-2" label="Shopify ID" value={shopifyInfo?.id_short}>
      <a
        className="link"
        href={shopifyInfo?.product_url ?? "#"}
        rel="noopener noreferrer"
        target="_blank"
      >
        {shopifyInfo?.id_short}
      </a>
      {shopifyInfo?.id_short && (
        <CopyToClipboardButton className="text-xs btn_xs" text={shopifyInfo.id_short} />
      )}
    </Field>
  );
}

function ShopifyTags({ product }: ProductOverviewProps) {
  if (!product.shopify_info || product.shopify_info.tag_list.length === 0) return null;

  return (
    <Field
      className="flex flex-wrap gap-1 gap-y-2"
      label="Tags"
      value={product.shopify_info.tag_list.length}
    >
      {product.shopify_info.tag_list.map((tag) => (
        <span
          className="text-xs text-gray-500 hover:text-gray-700 dark:hover:text-gray-400 bg-gray-100 dark:bg-gray-800/80 hover:bg-gray-200/50 dark:hover:bg-gray-800 rounded py-0.5 px-2"
          key={tag}
        >
          {tag}
        </span>
      ))}
    </Field>
  );
}

function TimestampColumns({ columns }: { columns: TimestampColumn[] }) {
  return (
    <div className="grid grid-flow-col auto-cols-max gap-6">
      {columns.map((column) => (
        <div className="flex flex-col gap-1" key={column.key}>
          <span className="my-1 text-xs/1 font-medium uppercase tracking-wide text-gray-400 dark:text-gray-400">
            {column.label}
          </span>
          <span className="text-sm">{column.value}</span>
        </div>
      ))}
    </div>
  );
}

function formatList(values: string[]) {
  const presentValues = values.filter(Boolean);

  return presentValues.length > 0 ? presentValues.join(", ") : null;
}
