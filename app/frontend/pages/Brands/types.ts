export type BrandRecord = {
  created_at: string | null;
  id: number | null;
  updated_at: string | null;
  title: string;
};

export type BrandErrors = Partial<Record<"title", string[]>>;

export type ProductRecord = {
  full_title: string;
  id: number;
  path: string;
};
