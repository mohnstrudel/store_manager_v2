export type SizeRecord = {
  id: number | null;
  value: string;
  created_at: string | null;
  updated_at: string | null;
};

export type SizeErrors = Partial<Record<"value", string[]>>;

export type ProductRecord = {
  id: number;
  full_title: string;
  path: string;
};
