export type SalesTagColor =
  | "green"
  | "pink"
  | "taupe"
  | "sky"
  | "violet"
  | "fuchsia"
  | "mauve"
  | "olive";

export type SalesTagRecord = {
  id: number;
  name: string;
  color: SalesTagColor;
};
