# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Account', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent) { create(:agent) }

  before do
    visit '/'
    find("[aria-label=\"Avatar (#{agent.fullname})\"]").click
  end

  describe 'appearance selection' do
    it 'user can switch appearance' do
      # Switch starts on 'auto'
      default_theme = page.execute_script("return matchMedia('(prefers-color-scheme: dark)').matches") ? 'dark' : 'light'
      expect(page).to have_css("html[data-theme=#{default_theme}]")

      # Switch to 'dark'
      click_on 'Appearance'
      wait_for_mutation('userCurrentAppearance')
      expect(page).to have_css('html[data-theme=dark]')

      # Switch to 'light'
      click_on 'Appearance'
      wait_for_mutation('userCurrentAppearance', number: 2)
      expect(page).to have_css('html[data-theme=light]')

    end
  end

  describe 'language selection' do
    it 'user can change language' do
      click_on 'Profile settings'
      click_on 'Language'

      find('label', text: 'Your language').click
      find('span', text: 'Deutsch').click
      expect(page).to have_text('Sprache')
    end
  end

  describe 'password change' do
    let(:agent) { create(:agent, password: 'test') }

    it 'user can change password' do
      click_on 'Profile settings'
      click_on 'Password'

      fill_in 'Current password', with: 'test'
      fill_in 'New password', with: 'testTEST1234'
      fill_in 'Confirm new password', with: 'testTEST1234'

      click_on 'Change Password'

      expect(page).to have_text('Password changed successfully')
    end
  end

  describe 'token handling' do
    let(:agent) { create(:admin) }

    it 'user can create and use a token' do
      click_on 'Profile settings'
      click_on 'Token Access'

      click_on 'New Personal Access Token'

      fill_in 'Name', with: 'Test Token'

      # Activate some permissions for the token
      find('span', text: 'Configure your system.').click
      find('span', text: 'Manage personal settings.').click

      click_on 'Create'
      wait_for_mutation('userCurrentAccessTokenAdd')

      expect(Token.last.name).to eq('Test Token')
      expect(Token.last.permissions.map(&:name)).to eq(%w[admin user_preferences])
      expect(Token.last.check?).to be(true)
    end
  end

  describe 'avatar handling', authenticated_as: :agent do
    let(:agent) { create(:agent, firstname: 'Jane', lastname: 'Doe') }

    it 'user can upload avatar' do
      click_on 'Profile settings'
      click_on 'Avatar'

      expect(page).to have_text('JD')
      find('input[data-test-id="fileUploadInput"]', visible: :all).set(Rails.root.join('test/data/image/1000x1000.png'))
      expect(page).to have_text('Avatar Preview')
      click_on 'Save'

      expect(page).to have_text('Your avatar has been uploaded')

      avatar_element_style = find("#user-menu span[aria-label=\"Avatar (#{agent.fullname})\"]").style('background-image')
      expect(avatar_element_style['background-image']).to include("/api/v1/users/image/#{Avatar.last.store_hash}")
    end
  end
end
