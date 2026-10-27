export type SalesTagColor = "red" | "yellow" | "green" | "blue" | "violet" | "fuchsia";

export type SalesTagRecord = {
  id: number;
  name: string;
  color: SalesTagColor;
};
