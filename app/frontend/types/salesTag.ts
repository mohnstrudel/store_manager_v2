export type SalesTagColor = "gray" | "red" | "yellow" | "green" | "blue" | "violet" | "fuchsia";

export type SalesTagRecord = {
  id: number;
  name: string;
  color: SalesTagColor;
};
