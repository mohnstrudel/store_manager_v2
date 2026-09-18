import { describe, expect, it } from "vitest";

import { emptyToNull, isEmptyValue } from "./emptyValue";

describe("isEmptyValue", () => {
  it("treats null as empty", () => {
    expect(isEmptyValue(null)).toBe(true);
  });

  it("treats undefined as empty", () => {
    expect(isEmptyValue(undefined)).toBe(true);
  });

  it("treats an empty string as empty", () => {
    expect(isEmptyValue("")).toBe(true);
  });

  it("treats a numeric zero as empty", () => {
    expect(isEmptyValue(0)).toBe(true);
  });

  it("does not treat a non-empty string as empty", () => {
    expect(isEmptyValue("0.00")).toBe(false);
  });

  it("does not treat a non-zero number as empty", () => {
    expect(isEmptyValue(5)).toBe(false);
  });

  it("does not treat a whitespace string as empty", () => {
    expect(isEmptyValue(" ")).toBe(false);
  });
});

describe("emptyToNull", () => {
  it("passes through a non-empty string", () => {
    expect(emptyToNull("alpha")).toBe("alpha");
  });

  it("passes through a non-zero number", () => {
    expect(emptyToNull(42)).toBe(42);
  });

  it("nulls out null", () => {
    expect(emptyToNull(null)).toBeNull();
  });

  it("nulls out undefined", () => {
    expect(emptyToNull(undefined)).toBeNull();
  });

  it("nulls out an empty string", () => {
    expect(emptyToNull("")).toBeNull();
  });

  it("nulls out a numeric zero", () => {
    expect(emptyToNull(0)).toBeNull();
  });
});
