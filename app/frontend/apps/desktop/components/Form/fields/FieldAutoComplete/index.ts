// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  AutoCompleteProps,
  AutocompleteSelectValue,
} from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldAutoCompleteInput from './FieldAutoCompleteInput.vue'

import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    autocomplete: AutoCompleteProps & {
      type: 'autocomplete'
      value: AutocompleteSelectValue | null
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    treeselect: FormKitBaseSlots<Props>
  }
}

export const autoCompleteProps = [
  'alternativeBackground',
  'action',
  'actionIcon',
  'actionLabel',
  'additionalQueryParams',
  'allowUnknownValues',
  'clearable',
  'debounceInterval',
  'defaultFilter',
  'filterInputPlaceholder',
  'filterInputValidation',
  'limit',
  'multiple',
  'noOptionsLabelTranslation',
  'belongsToObjectField',
  'optionIconComponent',
  'dialogNotFoundMessage',
  'dialogEmptyMessage',
  'options',
  'initialOptionBuilder',
  'sorting',
  'complexValue',
  'clearValue',
]

const fieldDefinition = createInput(
  FieldAutoCompleteInput,
  [...autoCompleteProps, 'gqlQuery'],
  { features: [addLink, formUpdaterTrigger()] },
)

export default {
  fieldType: 'autocomplete',
  definition: fieldDefinition,
}
