export type VersionRecord = {
  created_at: string | null;
  id: number | null;
  updated_at: string | null;
  value: string;
};

export type VersionErrors = Partial<Record<"value", string[]>>;

export type ProductRecord = {
  full_title: string;
  id: number;
  path: string;
};
