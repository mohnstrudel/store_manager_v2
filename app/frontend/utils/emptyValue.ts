type EmptyableValue = string | number | null | undefined;

export function emptyToNull<T extends string | number>(value: T | null | undefined): T | null {
  return value === null || value === undefined || value === "" || value === 0 ? null : value;
}

export function isEmptyValue(value: EmptyableValue): boolean {
  return value === null || value === undefined || value === "" || value === 0;
}
