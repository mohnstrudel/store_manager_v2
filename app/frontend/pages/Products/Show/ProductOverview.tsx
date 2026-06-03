import CopyToClipboardButton from "@/components/CopyToClipboardButton";
import ImageGallery from "../components/ImageGallery";
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
    <div className="card grow">
      <h5>Title</h5>
      <p>{product.title}</p>
      <h5>Franchise</h5>
      <p>{product.franchise.title}</p>
      <h5>Version</h5>
      <p>{formatList(product.versions.map((version) => version.value))}</p>
      <h5>Brand</h5>
      <p>{formatList(product.brands.map((brand) => brand.title))}</p>
      <h5>Size</h5>
      <p>{formatList(product.sizes.map((size) => size.value))}</p>
      <h5>Shape</h5>
      <p>{product.shape}</p>
      <h5>Color</h5>
      <p>{formatList(product.colors.map((color) => color.value))}</p>
    </div>
  );
}

function StoreIdentifiersCard({ product }: ProductOverviewProps) {
  return (
    <div className="card w-min">
      <h5>ID</h5>
      <p>{product.id}</p>
      <h5>Created&nbsp;At</h5>
      <TimestampColumns columns={product.created_at_columns} />
      <h5>Updated&nbsp;At</h5>
      <TimestampColumns columns={product.updated_at_columns} />
      <h5>Woo ID</h5>
      <WooIdentifier product={product} />
      <h5>Shopify ID</h5>
      <ShopifyIdentifier product={product} />
      <ShopifyTags product={product} />
    </div>
  );
}

function WooIdentifier({ product }: ProductOverviewProps) {
  const wooInfo = product.woo_info;

  if (!wooInfo?.store_id) return <p>-</p>;

  return (
    <>
      <p>
        {wooInfo.product_url ? (
          <ExternalStoreLink href={wooInfo.product_url}>{wooInfo.store_id}</ExternalStoreLink>
        ) : (
          wooInfo.store_id
        )}
      </p>
      <CopyStoreIdButton storeId={wooInfo.store_id} />
    </>
  );
}

function ShopifyIdentifier({ product }: ProductOverviewProps) {
  const shopifyInfo = product.shopify_info;

  if (!shopifyInfo?.id_short) return <p>-</p>;

  return (
    <>
      <p className="flex gap-2">
        <ExternalStoreLink href={shopifyInfo.product_url ?? "#"}>
          {shopifyInfo.id_short}
        </ExternalStoreLink>
      </p>
      <CopyStoreIdButton storeId={shopifyInfo.id_short} />
    </>
  );
}

function ShopifyTags({ product }: ProductOverviewProps) {
  if (!product.shopify_info || product.shopify_info.tag_list.length === 0) return null;

  return (
    <>
      <h5>Tags</h5>
      <p className="flex flex-wrap gap-1 gap-y-2">
        {product.shopify_info.tag_list.map((tag) => (
          <span
            className="text-xs text-gray-500 hover:text-gray-700 dark:hover:text-gray-400 bg-gray-100 dark:bg-gray-800/80 hover:bg-gray-200/50 dark:hover:bg-gray-800 rounded py-0.5 px-2"
            key={tag}
          >
            {tag}
          </span>
        ))}
      </p>
    </>
  );
}

type ExternalStoreLinkProps = {
  children: string;
  href: string;
};

function ExternalStoreLink({ children, href }: ExternalStoreLinkProps) {
  return (
    <a className="link" href={href} rel="noopener noreferrer" target="_blank">
      {children}
    </a>
  );
}

function CopyStoreIdButton({ storeId }: { storeId: string }) {
  return <CopyToClipboardButton className="text-xs btn_xs" text={storeId} />;
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

  return presentValues.length > 0 ? presentValues.join(", ") : "-";
}
