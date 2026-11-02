export type SalesTagColor = "green" | "pink" | "mauve" | "sky" | "violet" | "olive";

export type SalesTagRecord = {
  id: number;
  name: string;
  color: SalesTagColor;
};
