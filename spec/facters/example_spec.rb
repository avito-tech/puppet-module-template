# frozen_string_literal: true

require 'spec_helper'

describe Facter::Util::Fact do
  before(:each) { Facter.clear }

  context 'some context' do
    before(:each) do
      # мокаем вызовы внешних программ или 
      # allow(Facter::Util::Resolution).to receive(:which).with('your-binary') { true }
      # allow(Facter::Util::Resolution).to receive(:exec).with('your-binary') { 'something' }
    end
    it { expect(Facter.fact(:facter_lxd).value).to eq('something') }
  end
end