import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import NestedFormContainer from "@/components/NestedFormContainer";

import type { SaleAddressFormRecord } from "../../types";

type AddressFieldsProps = {
  address: SaleAddressFormRecord;
  namePrefix: string;
  title: string;
};

export default function AddressFields({ address, namePrefix, title }: AddressFieldsProps) {
  return (
    <NestedFormContainer title={title}>
      <FormRow className="pt-4 lg:pt-0">
        <FormInput
          defaultValue={address.first_name}
          label="First name"
          name={`${namePrefix}[first_name]`}
        />
        <FormInput
          defaultValue={address.last_name}
          label="Last name"
          name={`${namePrefix}[last_name]`}
        />
      </FormRow>
      <FormRow>
        <FormInput
          defaultValue={address.email}
          label="Email"
          name={`${namePrefix}[email]`}
          type="email"
          className="lg:w-2/3"
        />
        <FormInput
          defaultValue={address.phone}
          label="Phone"
          name={`${namePrefix}[phone]`}
          className="lg:w-1/3"
        />
      </FormRow>

      <FormInput
        defaultValue={address.address_1}
        label="Address 1"
        name={`${namePrefix}[address_1]`}
      />

      <FormInput
        defaultValue={address.address_2}
        label="Address 2"
        name={`${namePrefix}[address_2]`}
      />

      <FormRow>
        <FormInput
          defaultValue={address.country}
          label="Country"
          name={`${namePrefix}[country]`}
          className="lg:w-2/3"
        />
        <FormInput
          defaultValue={address.state}
          label="State"
          name={`${namePrefix}[state]`}
          className="lg:w-1/3"
        />
      </FormRow>

      <FormRow>
        <FormInput
          defaultValue={address.city}
          label="City"
          name={`${namePrefix}[city]`}
          className="lg:w-3/4"
        />
        <FormInput
          defaultValue={address.postcode}
          label="Postcode"
          name={`${namePrefix}[postcode]`}
          className="lg:w-1/4"
        />
      </FormRow>

      <FormInput defaultValue={address.company} label="Company" name={`${namePrefix}[company]`} />
    </NestedFormContainer>
  );
}
