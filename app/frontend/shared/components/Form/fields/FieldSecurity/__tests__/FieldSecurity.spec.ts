// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import Form from '#shared/components/Form/Form.vue'
import { renderComponent } from '#tests/support/components/index.ts'

const renderSecurityField = (props: any = {}) => {
  return renderComponent(FormKit, {
    form: true,
    formField: true,
    props: {
      type: 'security',
      name: 'security',
      label: 'Security',
      ...props,
    },
  })
}

describe('FieldSecurity', () => {
  it('renders security options', async () => {
    const view = renderSecurityField({
      allowed: ['encryption', 'sign'],
    })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })

    expect(encrypt).toBeInTheDocument()
    expect(sign).toBeInTheDocument()

    expect(encrypt).toBeEnabled()
    expect(sign).toBeEnabled()
  })

  it('can check and uncheck options', async () => {
    const view = renderSecurityField({
      allowed: ['encryption', 'sign'],
    })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'true')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(sign)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'true')

    await view.events.click(sign)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')
  })

  it("doesn't check disabled options", async () => {
    const view = renderSecurityField({
      allowed: [],
    })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })

    expect(encrypt).toBeDisabled()
    expect(sign).toBeDisabled()

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')
  })

  it("doesn't submit form on click", async () => {
    const onSubmit = vi.fn()
    const view = renderComponent(Form, {
      form: true,
      formField: true,
      props: {
        onSubmit,
        schema: [
          {
            type: 'security',
            name: 'security',
            label: 'Security',
            props: {
              allowed: ['encryption', 'sign'],
            },
          },
        ],
      },
    })

    await view.events.click(
      await view.findByRole('option', { name: 'Encrypt' }),
    )

    expect(onSubmit).not.toHaveBeenCalled()

    await view.events.click(await view.findByRole('option', { name: 'Sign' }))

    expect(onSubmit).not.toHaveBeenCalled()
  })
})

describe('rendering security messages', () => {
  it("doesn't render if there are no messages", () => {
    const view = renderSecurityField({
      allowed: ['encryption', 'sign'],
      securityMessages: {},
    })

    expect(view.queryByTestId('tooltipTrigger')).not.toBeInTheDocument()
  })

  it('renders both messages correctly', async () => {
    const view = renderSecurityField({
      allowed: ['encryption', 'sign'],
      securityMessages: {
        encryption: { message: 'Custom encryption message' },
        sign: { message: 'Custom sign message' },
      },
    })

    await view.events.click(view.getByTestId('tooltipTrigger'))

    expect(view.baseElement).toHaveTextContent(
      'Encryption: Custom encryption message',
    )
    expect(view.baseElement).toHaveTextContent('Sign: Custom sign message')
    expect(view.baseElement).toHaveTextContent('Security Information')
  })
})
