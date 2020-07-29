# frozen_string_literal: true

require 'spec_helper'

describe 'vault::example' do
  context 'some context' do
    it { should run.with_params('example function input').and_return('example function output') }
  end
end