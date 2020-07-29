# frozen_string_literal: true

# Function description here
Puppet::Functions.create_function(:'module::examplefunc') do
  # @param [Type1] param Function parameter
  # @return [Type2] Description of the return value
  dispatch :example do
    param 'Type1', :param
    return_type 'Type2'
  end

  def example(param)
    ret = some_magic(param)
    ret
  end
end
