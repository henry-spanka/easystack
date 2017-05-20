require 'spec_helper'
describe 'easystack' do
  context 'with default values for all parameters' do
    it { should contain_class('easystack') }
  end
end
