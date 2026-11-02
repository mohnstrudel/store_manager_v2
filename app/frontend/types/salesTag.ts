export type SalesTagColor = "green" | "pink" | "taupe" | "sky" | "violet" | "olive";

export type SalesTagRecord = {
  id: number;
  name: string;
  color: SalesTagColor;
};
