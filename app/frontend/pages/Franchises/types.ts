export type FranchiseRecord = {
  created_at: string | null;
  id: number | null;
  updated_at: string | null;
  title: string;
};

export type FranchiseErrors = Partial<Record<"title", string[]>>;

export type ProductRecord = {
  full_title: string;
  id: number;
  path: string;
};
